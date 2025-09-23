# http://localhost:8000/python/chat

# app/main.py
import os
import requests
from fastapi import FastAPI
from pydantic import BaseModel

BASE_URL = os.getenv("LLM_BASE_URL", "http://host.docker.internal:1234/v1")
API_KEY  = os.getenv("LLM_API_KEY", "lm-studio")
MODEL    = os.getenv("LLM_MODEL", "openai/gpt-oss-20b")

app = FastAPI()

class ChatIn(BaseModel):
    message: str
    model: str | None = None
    temperature: float | None = 0.2

@app.get("/health")
def health():
    return {"ok": True, "model": MODEL, "base_url": BASE_URL}

@app.post("/python/chat")
def chat(body: ChatIn):
    payload = {
        "model": body.model or MODEL,
        "messages": [{"role": "user", "content": body.message}],
        "temperature": body.temperature or 0.2,
    }
    r = requests.post(
        f"{BASE_URL}/chat/completions",
        headers={"Authorization": f"Bearer {API_KEY}"},
        json=payload,
        timeout=60,
    )
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"]

