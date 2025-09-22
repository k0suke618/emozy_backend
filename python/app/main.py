from fastapi import FastAPI
from pydantic import BaseModel
import os
from openai import OpenAI

app = FastAPI()

# 環境変数で差し替え（例）
# LLM_BASE_URL=http://llm:8000/v1   # vLLM OpenAI互換
# LLM_API_KEY=token-abc123
# LLM_MODEL=Qwen/Qwen2.5-7B-Instruct
BASE_URL = os.getenv("LLM_BASE_URL", "http://llm:8000/v1")
API_KEY  = os.getenv("LLM_API_KEY", "token-abc123")  # vLLMなら任意トークンでOKなことが多い
MODEL    = os.getenv("LLM_MODEL",  "Qwen/Qwen2.5-1.5B-Instruct")

client = OpenAI(base_url=BASE_URL, api_key=API_KEY)

class ChatIn(BaseModel):
    prompt: str
    system: str | None = None
    max_new_tokens: int = 256
    temperature: float = 0.7
    top_p: float = 0.9

@app.get("/health")
def health():
    return {"ok": True, "model": MODEL, "base_url": BASE_URL}

@app.post("/chat")
def chat(req: ChatIn):
    messages = []
    if req.system:
        messages.append({"role": "system", "content": req.system})
    messages.append({"role": "user", "content": req.prompt})

    resp = client.chat.completions.create(
        model=MODEL,
        messages=messages,
        max_tokens=req.max_new_tokens,
        temperature=req.temperature,
        top_p=req.top_p,
    )
    text = resp.choices[0].message.content
    return {"text": text}
