import json
from pathlib import Path
import pandas as pd

DATA_PATH = Path("data/invasion_personal_right_v01.jsonl")


df = pd.read_json(DATA_PATH, orient='records', lines=True)


print(f"データ件数: {len(df)}")
print(df.head())