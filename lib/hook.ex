defmodule DublinBusTelegramBot.Hook do
  use Maru.Router

  alias DublinBusTelegramBot.Commands, as: Commands

  require Logger

  # rescue_from :all, as: e do
  #   conn
  #   |> send_resp(200,"#{inspect(e)} - sending 200 anyway")
  # end

  route_param :token do
    namespace :hook do
      post do
        conn.body_params
        |> entry_point
        |> get_resp

        json(conn, %{})
      end

      get do
        {:ok, messages} = Nadia.get_updates()

        messages
        |> List.last()
        |> entry_point
        |> get_resp

        json(conn, %{})
      end
    end

    namespace :status do
      get do
        json(conn, %{ok: "System is running"})
      end

      head do
        json(conn, %{ok: "System is running"})
      end
    end

    # rescue_from :all, as: e do
    #   conn
    #   |> send_resp(200,"#{inspect(e)} - sending 200 anyway")
    # end
  end

  defp get_resp({_, resp}), do: resp
  defp get_resp(t), do: %{}

  use Commander

  dispatch to: Commands do
    command("/stop", [:stop])
    command("/watch", [:stop, :line])
    command("/search", [:q])
    command("/unwatch", [])
    command("/start", [])
    command("/info", [])
  end

  def polling(offset \\ 0) do
    try do
      {:ok, updates} = Nadia.get_updates([{:offset, offset}])

      update_id =
        for update <- updates do
          entry_point(update)
          update.update_id
        end
        |> List.last()

      offset =
        if update_id == nil do
          offset
        else
          update_id + 1
        end

      :timer.sleep(2000)
      spawn(fn -> polling(offset) end)
    catch
      _ -> nil
    end
  end
end
