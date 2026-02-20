# emozy_backend README

`emozy_backend` は、`emozy`（フロントエンド）と連携して動作するバックエンドです。  
このREADMEはバックエンド作業用です。全体像は `../emozy/README.md` を参照してください。

## フロントとの連携方針

- フロント実装: `../emozy`
- バックエンド実装: `./rails` と `./python`
- 開発時はバックエンドを先に起動し、その後フロントを起動します

## ディレクトリ構成

```text
emozy_backend/
├── rails/           # Rails APIサーバー（認証・DBアクセス・業務ロジック）
├── python/          # 文章生成サービス（LLM連携・テキスト生成処理）
├── docker-compose.yml
└── README.md
```

## 起動手順（バックエンド）

```bash
cd emozy_backend
docker compose build
docker compose up -d
```

停止:

```bash
docker compose down
```

## フロントと一緒に動かす手順

1. このディレクトリで `docker compose up -d` を実行
2. 別ターミナルで `../emozy` に移動
3. `npm install`（初回のみ）
4. `npm run dev`

## 関連README

- 全体説明: `../emozy/README.md`
- Rails詳細: `./rails/README.md`
