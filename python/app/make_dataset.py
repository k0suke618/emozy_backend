import pandas as pd
from pathlib import Path
import re

from config import JSONL_PATH, REPORT_TYPE_CSV_PATH
from llm import LLM, Prompt

def load_data(file_path):
    df = pd.read_json(file_path, orient='records', lines=True)
    return df

def load_report_type_data():
    df = pd.read_csv(REPORT_TYPE_CSV_PATH)
    return df


class Dataset:
    def __init__(self, toxic_df: pd.DataFrame):
        self.toxic_df = toxic_df
        self.llm = LLM()
        self.prompt = Prompt(language="JP")

    def get_toxic_texts(self) -> list:
        return self.toxic_df["本件投稿"].tolist()
    
    def get_generated_texts(self, role: str, n: int=200) -> list:
        prompt = self.prompt.generate_content_prompt(role=role)
        responses = [self.llm.inference(messages=[{"role": "user", "content": prompt}], temperature=1.5) for _ in range(n)]
        return responses

    def clean_texts(self) -> list:
        # テキストの前処理をここに実装
        # 改行を。に変換する
        texts = self.get_toxic_texts()
        cleaned_texts = [text.replace('\n', '。') for text in texts]
        
        # , を、に変換する
        cleaned_texts = [text.replace(',', '、') for text in cleaned_texts]
        
        # []に囲まれた部分を削除する
        # cleaned_texts = [re.sub(r'\[.*?\]', '', text) for text in cleaned_texts]
        
        # 連続する空白を1つにする
        cleaned_texts = [re.sub(r'\s+', ' ', text) for text in cleaned_texts]
        
        # 先頭と末尾の空白を削除する
        cleaned_texts = [text.strip() for text in cleaned_texts]
        
        return cleaned_texts
    
    def save_cleaned_texts(self, output_path: Path):
        # 有害コンテンツ
        print("start toxic content generation")
        cleaned_toxic_texts = self.clean_texts()
        with open(output_path, 'w', encoding='utf-8') as f:
            for text in cleaned_toxic_texts:
                f.write(text + ",1" + '\n')

        print("start student non-toxic content generation")
        # 学生コンテンツ
        cleaned_student_texts = self.get_generated_texts(role="情報学部の大学生", n=len(cleaned_toxic_texts)//2)
        with open(output_path, 'a', encoding='utf-8') as f:
            for text in cleaned_student_texts:
                f.write(text + ",0" + '\n')

        print("start worker non-toxic content generation")
        # 社員コンテンツ
        cleaned_worker_texts = self.get_generated_texts(role="社員", n=len(cleaned_toxic_texts)//2)
        with open(output_path, 'a', encoding='utf-8') as f:
            for text in cleaned_worker_texts:
                f.write(text + ",0" + '\n')
    
    def make_teaching_string(self, text: str, is_toxic: bool) -> str:
        """
        {"text":"<|system|>\nあなたは投稿が通報対象かを厳密に判定します。出力は \"0\" または \"1\" のみ。\n\"1\"=誹謗中傷など通報対象、\"0\"=その他。\n<|user|>\n思いついたことを話してみよとのことで1時間話していたらカウンセラーはその間パズル解いてたり昼寝したり、で、11,000を徴収。話すこともなくなってこれからどうなるんですかね？と聞いたらお得な割引パック物ありますよ、とのこと。何屋さんなのだか分けわかりませんでした。いやー、世の中にはボロい商売ってあるんですね。皆、苦しんでると思いますが、ぜひ他を当たって下さいね。\n<|assistant|>\n1"}
        """
        system_prompt = "{\"text\":\"<|system|>あなたは投稿が通報対象かを厳密に判定します。出力は 0 または 1 のみです。1=誹謗中傷など通報対象、0=通報対象ではないものです。"
        
        user_prompt = f"<|user|>{text}"
        
        assistant_prompt = f"<|assistant|>{1 if is_toxic else 0}"
        
        last_char = '"}'

        return f"{system_prompt}{user_prompt}{assistant_prompt}{last_char}"
    
    def make_teaching_data(self, input_csv_path: Path, output_jsonl_path: Path):
        df = pd.read_csv(input_csv_path, header=None, names=["content", "is_report"])
        with open(output_jsonl_path, 'w', encoding='utf-8') as f:
            for i, row in df.iterrows():
                if i == 0:
                    continue
                teaching_string = self.make_teaching_string(row["content"], bool(row["is_report"]))
                f.write(teaching_string + '\n')


if __name__ == "__main__":
    df = load_data(JSONL_PATH)

    type_df = load_report_type_data()

    dataset = Dataset(df)
    # texts = dataset.clean_texts()
    
    # dataset.save_cleaned_texts(Path('data/cleaned_texts.csv'))

    dataset.make_teaching_data(input_csv_path=Path('data/tweet.csv'), output_jsonl_path=Path('data/teaching_data.jsonl'))
    