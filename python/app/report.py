import os
import random
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Sequence

import pandas as pd
import requests
import re

BASE_URL = os.getenv("LLM_BASE_URL", "http://host.docker.internal:1234/v1")
API_KEY = os.getenv("LLM_API_KEY", "lm-studio")
MODEL = os.getenv("LLM_MODEL", "emozy_report_Q8_0/emozy_report_Q8_0.gguf")
REQUEST_TIMEOUT = float(os.getenv("LLM_REQUEST_TIMEOUT", "30"))
FORCE_TIMEOUT = float(os.getenv("LLM_FORCE_TIMEOUT", "5"))

JSONL_PATH = Path("data/invasion_personal_right_v01.jsonl")
REPORT_TYPE_CSV_PATH = Path("data/report_type.csv")


def call_llm(
    messages: Sequence[dict[str, Any]],
    *,
    temperature: float = 0.0,
    model: str | None = None,
    allow_force_completion: bool = True,
) -> dict[str, Any]:

    payload = {
        "model": model or MODEL,
        "messages": list(messages),
        "temperature": temperature,
    }

    def _post(timeout_value: float | None):
        return requests.post(
            f"{BASE_URL}/chat/completions",
            headers={"Authorization": f"Bearer {API_KEY}"},
            json=payload,
            timeout=timeout_value,
        )

    forced = False
    try:
        response = _post(REQUEST_TIMEOUT)
        response.raise_for_status()
    except requests.Timeout as original_timeout:
        if not allow_force_completion:
            raise
        try:
            forced_response = _post(FORCE_TIMEOUT if FORCE_TIMEOUT > 0 else None)
            forced_response.raise_for_status()
        except Exception as force_error:
            raise original_timeout from force_error
        else:
            response = forced_response
            forced = True

    data = response.json()
    message = data["choices"][0]["message"]
    if forced:
        message.setdefault("meta", {})
        message["meta"]["forced_completion"] = True
    return message


@dataclass
class ReportResult:
    is_report: bool
    raw_content: str
    reasoning: str | None = None


class Report:
    def __init__(self, language: str):
        self.language = language
        self.type_df = pd.read_csv(REPORT_TYPE_CSV_PATH)
        self.report_types = (
            self.type_df[self.type_df["language"] == language]["keyword"].tolist()
        )

    def _make_judgement_messages(self, post: str) -> list[dict[str, Any]]:
        return [
            {
                "role": "system",
                "content": (
                    "あなたは投稿が通報対象かを厳密に判定するモデレーターです。"
                    "必ず次のルールを守ってください。"
                    "1. 出力は半角数字の0または1を1文字だけ返す。改行・説明・記号は禁止。"
                    "2. 1=侮辱的・危険な表現など通報対象、0=通報対象外。"
                    "3. 少しでも炎上しそうな要素があれば通報対象とみなす。"
                    "4. 個人の特定につながる内容、差別的表現、誹謗中傷、プライバシー侵害、違法行為の助長などが含まれる場合は通報対象とみなす。"
                ),
            },
            {
                "role": "user",
                "content": f"次の投稿内容は通報対象ですか？0か1で答えてください。投稿内容：{post}",
            },
        ]

    def _predict(
        self,
        post: str,
        *,
        messages: list[dict[str, Any]] | None = None,
    ) -> dict[str, Any]:
        prompt_messages = messages or self._make_judgement_messages(post)
        return call_llm(prompt_messages)

    def summarize_reasoning(self, text: str) -> str:
        messages = [
            {
                "role": "system",
                "content": (
                    "あなたは通報理由を短文で要約するアシスタントです。"
                    "余計な説明や指示文を付けず、必ず1文で回答してください。"
                    "数字や記号、改行は禁止です。"
                    "通報理由は、「しつつ」や「ではなく」のような、言葉を使わず、簡潔な一言で出力してください。"
                    "侮辱ではなく、脅迫のように、種類を説明する回答は避けてください。"
                ),
            },
            {
                "role": "user",
                "content": "次の文章から通報理由だけを抜き出して要約してください。\n\n" + text,
            },
        ]
        message = call_llm(messages)
        return message.get("content", "")

    def judge_report_type(self, text: str) -> int:
        normalized = text.strip()

        if normalized.isdecimal():
            idx = int(normalized)
            if 0 <= idx < len(self.report_types):
                return idx

        for i, keyword in enumerate(self.report_types):
            if keyword in normalized:
                return i

        return -1

    def judge_report(self, text: str, show_log: bool = False) -> ReportResult:
        messages = self._make_judgement_messages(text)
        if show_log:
            for msg in messages:
                label = msg["role"]
                print(f"LLM Prompt({label}): {msg['content']}")
        message = self._predict(text, messages=messages)
        content = message.get("content", "")
        reasoning = message.get("reasoning")

        if show_log:
            print(f"LLM Result(content): {content}")
            print(f"LLM Result(reasoning): {reasoning}")

        normalized = content.strip()
        if normalized.isdecimal():
            is_report = normalized.startswith("1")
        elif "通報対象外" in normalized:
            is_report = False
        else:
            is_report = normalized.startswith("1") or "1" in normalized
            if not is_report and reasoning:
                is_report = "1" in reasoning

        return ReportResult(is_report=is_report, raw_content=content, reasoning=reasoning)

    def get_report_type(self, index: int) -> str:
        return self.report_types[index]


def get_random_post_content() -> str:
    df = pd.read_json(JSONL_PATH, orient="records", lines=True)
    length = len(df)
    random_index = random.randint(0, length - 1)
    return df.iloc[random_index]["本件投稿"]

def simple_no_mean_check(text: str) -> bool:
    # 無意味な投稿（同じ文字の入力）の簡易チェック
    # 正規表現を使って、同じ文字が2回以上連続する場合を検出
    if re.search(r'(.)\1{2,}', text):
        return True
    if len(text) == 1:
        return True
    return False


if __name__ == "__main__":
    report = Report(language="JP")
    sample_post = get_random_post_content()
    sample_post = "Aは詐欺で逮捕された前科がある"
    print(f"投稿内容: {sample_post}")
    result = report.judge_report(sample_post, show_log=True)
    print(f"通報対象: {result.is_report}")
    if result.is_report and result.reasoning:
        summary = report.summarize_reasoning(result.reasoning)
        print(f"通報理由: {summary}")
