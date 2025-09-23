import pandas as pd
import os
import requests
from pathlib import Path
import random


BASE_URL = os.getenv("LLM_BASE_URL", "http://host.docker.internal:1234/v1")
API_KEY  = os.getenv("LLM_API_KEY", "lm-studio")
MODEL    = os.getenv("LLM_MODEL", "openai/gpt-oss-20b")

JSONL_PATH = Path('data/invasion_personal_right_v01.jsonl')
REPORT_TYPE_CSV_PATH = Path('data/report_type.csv')

class Report:
    def __init__(self, language: str):
        self.language = language
        self.type_df = pd.read_csv(REPORT_TYPE_CSV_PATH)
        self.report_types = self.type_df[self.type_df['language'] == language]['keyword'].tolist()
        
    def _make_prompt(self, prompt: str, report_type: list) -> str:
        # プロンプトを整形して返す
        base_prompt = f"""
        以下は{self.language}のSNSの投稿です。
        この投稿を分析し、通報に値するかどうかを判断してください。
        通報に値する場合は、以下の通報理由の中から最も適切なものを1つ選び、その理由を説明してください。
        {', '.join(report_type)}
        通報に値しない場合は、「通報対象外」とだけ答えてください
        """
        
        base_prompt += f"\n投稿内容: {prompt}\n"
        
        return base_prompt
    
    def _predict(self, text: str) -> str:
        # llmの結果を返す
        prompt = self._make_prompt(text, self.report_types)
        payload = {
            "model": MODEL,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.2,
        }
        response = requests.post(f"{BASE_URL}/chat/completions", headers={"Authorization": f"Bearer {API_KEY}"}, json=payload)
        if response.status_code == 200:
            return response.json()["choices"][0]["message"]["content"]
        else:
            raise Exception(f"LLM API Error: {response.status_code} {response.text}")
    
    

    def judge_report_type(self, text: str) -> int:
        """
        通報か判定
        Arguments:
            text: 判定対象のテキスト
        Returns:
            -1: 通報対象外
            0以上: 通報対象(通報理由のindex)
        """
        # 通報判定ロジックをここに実装
        # 例: 特定のキーワードが含まれているかどうかで判定
        for i, keyword in enumerate(self.report_types):
            if keyword in text:
                return i
        raise Exception(f"Unknown response from LLM: {text}")

    def judge_report(self, text: str, show_log: bool=False) -> tuple[bool, str]:
        """
        通報か判定
        Arguments:
            text: 判定対象のテキスト
        Returns:
            bool: 通報判定結果
                True: 通報
                False: 通報しない
            str: LLMの返答
        """
        ret = self._predict(text)
        if show_log:
            print(f"LLM Result: {ret}")
        if "通報対象外" in ret:
            return False, ret
        return True, ret
    
    def get_report_type(self, index: int) -> str:
        return self.report_types[index]

def get_random_post_content() -> str:
    # ランダムに投稿内容を取得する(テスト用)
    df = pd.read_json(JSONL_PATH, orient='records', lines=True)
    length = len(df)
    random_index = random.randint(0, length - 1)
    return df.iloc[random_index]['本件投稿']


if __name__ == "__main__":
    # テストコード
    report = Report(language="JP")
    sample_post = get_random_post_content()
    print(f"投稿内容: {sample_post}")
    is_report, llm_response = report.judge_report(sample_post, show_log=True)
    print(f"通報判定: {is_report}")
    if is_report:
        report_type = report.judge_report_type(llm_response)
        print(f"通報理由: {report_type}: {report.get_report_type(report_type)}")