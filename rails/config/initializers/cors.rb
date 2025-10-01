# 開発用の例。必要に応じて本番は環境変数で切り替えると安全です
allowed_origins = [
  'http://localhost:3000',
  'http://127.0.0.1:3000',
  'http://192.168.0.105:3000',
  # 'https://localhost:3000', # Next.js を https で動かす場合は追加
  ENV.fetch('FRONTEND_ORIGIN', nil)
].compact

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    # Cookie/セッションを使わない（=トークン認証だけ）の場合
    resource '*',
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: %w[Authorization X-CSRF-Token]

    # --- Cookie/セッションを使う場合は↑をコメントアウトして代わりに↓を使う ---
    # resource '*',
    #   headers: :any,
    #   methods: %i[get post put patch delete options head],
    #   credentials: true,                      # ← これが重要（Set-Cookie/送信を許可）
    #   expose: %w[Authorization X-CSRF-Token]
  end
end
