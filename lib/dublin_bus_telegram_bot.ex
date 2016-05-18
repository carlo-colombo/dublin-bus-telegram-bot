defmodule DublinBusTelegramBot do
  use Maru.Router
  use Application
  import Plug.Conn

  require Logger

  plug Plug.Logger
  plug Plug.Parsers, parsers: [:urlencoded, :json],
    pass:  ["text/*"],
    json_decoder: Poison

  mount DublinBusTelegramBot.Hook


  def start(_,[:test]), do: {:ok, self}

  def start(_,[:prod]) do
    base_address = Application.get_env(:dublin_bus_telegram_bot, :base_address)
    token = Application.get_env(:nadia, :token)
    hook = "#{base_address}/#{token}/hook"

    case Nadia.set_webhook([{:url, hook}]) do
      {:error, error} ->
        Nadia.set_webhook([{:url, ""}])
        Logger.warn "Cannot set up webhook #{hook}: #{error.reason}, removing actual webhook - setting up a polling"
        DublinBusTelegramBot.Hook.polling
      resp ->
        Logger.debug "Set up webhook #{hook}: #{inspect(resp)}"
    end

    {:ok, self}
  end
  def start(_,_) do
    Logger.info("Setting up polling")
    DublinBusTelegramBot.Hook.polling()
    {:ok, self}
  end

  rescue_from :all, as: e do
    inspect(e)
    |> Logger.error

    conn
    |> put_status(500)
    |> text("Run time error: #{e.__struct__}")
  end
end
