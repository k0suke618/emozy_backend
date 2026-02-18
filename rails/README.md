# emozy_backend/rails README

このディレクトリは `emozy` 用 Rails API (`:3333`) です。  
リポジトリ全体の説明は `../../emozy/README.md`、バックエンド全体の説明は `../README.md` を参照してください。

## ローカル実行（推奨: docker compose）

通常は `emozy_backend` 直下で以下を実行します。

```bash
cd ../
docker compose up -d
```

## 主なAPIベースパス

`http://localhost:3333/api/v1`

主なエンドポイント:

- `POST /signup`
- `POST /signin`
- `GET /posts`
- `POST /posts`
- `POST /search`
- `GET /ranking`
- `POST /ranking`
- `POST /report`
