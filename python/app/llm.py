from pydantic import BaseModel
import requests
from config import BASE_URL, API_KEY, MODEL, STUDENT_CONTEXT_PATH, TEACHER_CONTEXT_PATH, WORKER_CONTEXT_PATH

class ChatIn(BaseModel):
    message: str
    model: str | None = None
    temperature: float | None = 0.2

class Prompt:
    def __init__(self, language: str="JP"):
        self.language = language
        self.contexts = self._load_context()

    def _load_context(self) -> str:
        context_dict = dict()
        with open(STUDENT_CONTEXT_PATH, 'r', encoding='utf-8') as f:
            context_dict['student'] = f.read()
        with open(WORKER_CONTEXT_PATH, 'r', encoding='utf-8') as f:
            context_dict['worker'] = f.read()
        return context_dict
    
    def role2key(self, role: str) -> str:
        role_map = {
            "情報学部の大学生": "student",
            "社員": "worker",
        }
        return role_map.get(role, "student")


    def generate_judge_prompt(self) -> str:
        return f"""
        以下は{self.language}のSNSの投稿です。
        この投稿を分析し、通報対象にすべきかを判断してください。
        通報すべき場合は、1を、通報すべきでない場合は、0を返してください。
        """

    def generate_content_prompt(self, role: str) -> str:
        key = self.role2key(role)
        return f"""
        これは{self.language}のSNSの投稿を作成するタスクです。
        あなたは、{role}として振る舞います。
        以下の制約条件をもとに、SNSの投稿を出力してください。
        制約条件:
        ・出力は140字以内であること
        ・箇条書きではなく、自然な文章であること
        ・絵文字は使わないこと
        ・敬語は使わないこと
        ・投稿は{self.language}で書くこと
        ・{role}は以下のコンテキストを持っています。
        {self.contexts[key]}
        """

class LLM:
    def __init__(self):
        self.base_url = BASE_URL
        self.api_key = API_KEY
        self.model = MODEL
        
        
        
    def inference(self, messages: list[dict], model: str | None = None, temperature: float | None = 0.2) -> str:
        payload = {
            "model": model or self.model,
            "messages": messages,
            "temperature": temperature or 0.2,
        }
        r = requests.post(
            f"{self.base_url}/chat/completions",
            headers={"Authorization": f"Bearer {self.api_key}"},
            json=payload,
            timeout=60,
        )
        r.raise_for_status()
        return r.json()["choices"][0]["message"]["content"]