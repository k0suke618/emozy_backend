# http://localhost:8000/python/chat

# app/main.py
import requests
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from report import BASE_URL, MODEL, Report, call_llm
from report import simple_no_mean_check, dangerous_content_check

app = FastAPI()

class ChatIn(BaseModel):
    message: str
    model: str | None = None
    temperature: float | None = 0.2

@app.get("/health")
def health():
    return {"ok": True, "model": MODEL, "base_url": BASE_URL}

def _safe_llm_call(*, messages, temperature: float, model: str | None = None) -> dict:
    try:
        return call_llm(messages, temperature=temperature, model=model)
    except requests.Timeout as exc:
        raise HTTPException(status_code=504, detail="LLM request timed out") from exc
    except requests.RequestException as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc


# test用API
@app.post("/python/chat")
def chat(body: ChatIn):
    message = _safe_llm_call(
        messages=[{"role": "user", "content": body.message}],
        temperature=body.temperature or 0.2,
        model=body.model or MODEL,
    )
    return message.get("content", "")

# 通報判定API
@app.post("/python/judge_report")
def judge_report(body: ChatIn):
    report = Report(language="JP")
    # 文章が入力されたかチェック
    if simple_no_mean_check(body.message):
        return {
            "is_report": False,
            "response": "",
            "detail": "文章を入力してください",
        }
    if dangerous_content_check(body.message):
        return {
            "is_report": True,
            "response": "",
            "detail": "不適切な内容が含まれています",
        }
    try:
        result = report.judge_report(body.message)
    except requests.Timeout as exc:
        raise HTTPException(status_code=504, detail="LLM request timed out") from exc
    except requests.RequestException as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    except Exception as exc:
        # エラー発生時もAPIは200で返し、クライアントに理由を知らせる
        return {
            "is_report": False,
            "response": "",
            "detail": str(exc),
        }

    summary = ""
    if result.is_report:
        try:
            summary_source = result.reasoning or body.message
            summary = report.summarize_reasoning(summary_source)
            # "。"の後の文章は不要なので削除
            if "。" in summary:
                summary = summary.split("。")[0] + "。"
        except requests.Timeout as exc:
            raise HTTPException(status_code=504, detail="Summary request timed out") from exc
        except requests.RequestException as exc:
            raise HTTPException(status_code=502, detail=str(exc)) from exc

    return {
        "is_report": result.is_report,
        "response": summary,
        "detail": "",
    }
