from pathlib import Path
import os
import enum

# 教師データ
JSONL_PATH = Path('data/invasion_personal_right_v01.jsonl')
REPORT_TYPE_CSV_PATH = Path('data/report_type.csv')

# contexts
CONTEXT_DIR = Path('data/contexts')
STUDENT_CONTEXT_PATH = CONTEXT_DIR / 'student_context.txt'
TEACHER_CONTEXT_PATH = CONTEXT_DIR / 'teacher_context.txt'
WORKER_CONTEXT_PATH = CONTEXT_DIR / 'worker_context.txt'



BASE_URL = os.getenv("LLM_BASE_URL", "http://host.docker.internal:1234/v1")
API_KEY  = os.getenv("LLM_API_KEY", "lm-studio")
MODEL    = os.getenv("LLM_MODEL", "openai/gpt-oss-20b")

if __name__ == "__main__":
    print(f"BASE_URL: {BASE_URL}")
    print(f"API_KEY: {API_KEY}")
    print(f"MODEL: {MODEL}")