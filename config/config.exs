use Mix.Config

port =
(System.get_env("PORT") || "8081")
|> Integer.parse
|> elem(0)

base_address = System.get_env("BASE_ADDRESS") || "http://localhost:#{port}"

token = System.get_env("TELEGRAM_BOT_TOKEN")
google_analytics = System.get_env("GOOGLE_ANALYTICS")

config :nadia,
  token: token

config :maru, DublinBusTelegramBot,
http: [port: port]

config :dublin_bus_telegram_bot,
  base_address: base_address

config :meter,
  tid: google_analytics,
  dimensions:  [:stop, :line, :q],
  mapping: [
    cid: :chat_id
  ]
