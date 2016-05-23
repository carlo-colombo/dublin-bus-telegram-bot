defmodule DublinBusTelegramBot.Hook do
  use Maru.Router

  alias DublinBusTelegramBot.Commands, as: Commands

  require Logger

  route_param :token do
    namespace :hook do
      post do
        data = conn.body_params
        json conn, entry_point(data) |> get_resp
      end

      get do
        {:ok, messages } = Nadia.get_updates
        json conn, messages
        |> List.last
        |> entry_point
        |> get_resp
      end
    end

    namespace :status do
      get do
        json conn, %{ok: "System is running"}
      end
    end
  end

  defp get_resp({_, resp}), do: resp

  use Commander

  dispatch to: Commands do
    command "/stop",   [:stop]
    command "/watch",  [:stop, :line ]
    command "/search", [:q]
    command "/unwatch",[]
    command "/start",  []
  end


  def polling(offset \\ 0) do
    # Logger.info("Polling, offset: #{offset}")

    try do
      {:ok, updates } = Nadia.get_updates([{:offset, offset}])
      update_id = for update <- updates do
        entry_point(update)
        update.update_id
      end |> List.last

      offset = if update_id == nil do
        offset
      else
        update_id + 1
      end

      :timer.sleep(2000)
      spawn(fn  -> polling(offset) end)
    catch _->nil end
  end
end
