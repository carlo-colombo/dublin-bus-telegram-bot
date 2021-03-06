defmodule DublinBusTelegramBot do
  use Maru.Router
  use Application
  import Plug.Conn

  require Logger

  plug(Plug.Logger)

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["text/*"],
    json_decoder: Poison
  )

  plug(TokenValidation, paths: [:status, :hook])
  mount(DublinBusTelegramBot.Hook)

  plug(:set_200)

  def start(_, [:test]), do: {:ok, self}

  def start(_, [:prod]) do
    base_address = Application.get_env(:dublin_bus_telegram_bot, :base_address)
    token = Application.get_env(:nadia, :token)
    hook = "#{base_address}/#{token}/hook"

    case Nadia.set_webhook([{:url, hook}]) do
      {:error, error} ->
        Nadia.set_webhook([{:url, ""}])

        Logger.warn(
          "Cannot set up webhook #{hook}: #{error.reason}, removing actual webhook - setting up a polling"
        )

        DublinBusTelegramBot.Hook.polling()

      resp ->
        Logger.debug("Set up webhook #{hook}: #{inspect(resp)}")
    end

    {:ok, self}
  end

  def start(_, _) do
    Logger.info("Setting up polling")
    DublinBusTelegramBot.Hook.polling()
    {:ok, self}
  end

  rescue_from :all, as: e do
    Logger.error("Exception: #{inspect(e)}")

    conn
    |> put_status(200)
    |> text("Server Error")
  end

  defp set_200(conn, _options) do
    Logger.info("old status #{inspect(conn.status)}")
    conn = put_status(conn, 200)
    Logger.info("new status #{inspect(conn.status)}")
    conn
  end
end
