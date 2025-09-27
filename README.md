# Docker 起動

1. docker desktop を起動
2. `docker compose build`
3. `docker compose up -d`

# Docker 停止

`docker compose down --remove-orphans`

# python api

POST: `http://localhost:8000/python/chat`

JSON: {
"message": "Hello!"
}
