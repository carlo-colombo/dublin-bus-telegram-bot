defmodule DublinBusTelegramBot.Commands do
  require Logger
  import Meter

  @as_markdown [{:parse_mode, "Markdown"}]

  defmeter start(chat_id) do
    Nadia.send_message(chat_id, "
    Welcome to the Dublin Bus bot:

Access to the *Real Time Passenger Information (RTPI)* for Dublin Bus services. Data are retrieved parsing the still-in-development RTPI site. The html could change without notice and break the API, we don't take any responsibility for missed bus. The bot is precise as the dublin bus application or the screen at the stops.

_This service is in no way affiliated with Dublin Bus or the providers of the RTPI service_.

Available commands

/stop <stop number>
Retrieve upcoming timetable at this stop
``` /stop 4242```

/watch <stop number> <line>
Send you a message every minute with ETA of the bus at the stop. It stop after the bus is Due or until command unwatch is sent. Only one watch at time is possible.
``` /watch 4242 184```

/unwatch
Stop watch
``` /unwatch```

/search <query>
Search stops that match the name, if only one result is found it send also the timetable.
``` /search Townsend Street```

/info
Return some info about the bot
``` /info```

", @as_markdown)
    %{}
  end

  defmeter stop(chat_id, stop, update), do: handle_stop(chat_id, stop, update)

  defp handle_stop(chat_id, "IL" <> stop, %{callback_query: %{message: %{message_id: message_id}}}) do
    {text, options} = stop
    |> Stop.get_info
    |> timetable(stop)

    {:ok, _} = Nadia.API.request("editMessageText", [chat_id: chat_id, message_id: message_id, text: text] ++ options)
  end

  defp handle_stop(chat_id, stop, _) do
    stop
    |> Stop.get_info
    |> send_timetable(chat_id, stop)
  end

  defmeter info(chat_id) do
    apps = Application.loaded_applications
    {_, _, app_version} = List.keyfind(apps, :dublin_bus_telegram_bot, 0)
    {_, _, api_version} = List.keyfind(apps, :dublin_bus_api, 0)

    Nadia.send_message(chat_id, """
    Bot version: *#{app_version}*
    API version: *#{api_version}*
    API last time checked: *#{Stop.last_time_checked_formatted}*

    Bot icon made by Baianat from www.flaticon.com
    """, @as_markdown)

    Stop.last_time_checked_formatted
    %{}
  end

  defmeter watch(chat_id, stop, line) do
    job = %Quantum.Job{
      schedule: "* * * * *",
      task: fn -> send_short_message(chat_id, stop, line) end
    }
    Quantum.add_job(chat_id, job)
    Nadia.send_message(chat_id, "Watch set",[
          {:reply_markup, %{keyboard: [["/unwatch"]]}}])
    send_short_message(chat_id, stop, line)
    %{}
  end

  defmeter unwatch(chat_id) do
    Quantum.delete_job(chat_id)
    %{}
  end

  defp join_line({line, destination}), do: "#{line} #{destination}"

  defp join_stop(stop) do
    lines = stop.lines
    |> Enum.map(&join_line/1)
    |> Enum.join("\n")

    "** #{stop.ref} - #{stop.name} \n #{lines}"
  end

  defmeter search(chat_id, q) do
    data = Stop.search(q)

    case length(data) do
      1 ->
        Nadia.send_message(chat_id, "Search return only 1 result, here is the timetable")
        [stop] = data
        send_timetable(stop, chat_id ,stop.ref)
      x ->
        Nadia.send_message(chat_id, "Search return #{x} results")

        message = data
        |> Enum.map(&join_stop/1)
        |> Enum.join("\n")

        Nadia.send_message(chat_id, "```\n#{message}```", @as_markdown)
    end
    data
  end

  defmeter not_implemented(chat_id, command) do
    Nadia.send_message(chat_id, "Not yet implemented")

    warn = "#{command} not yet implemented"
    |> Logger.warn

    %{warn: warn}
  end

  defp to_button(text) when is_binary(text), do: %{text: text, callback_data: text}
  defp to_button(button), do: button

  defp timetable(data, stop) do
    title = "*#{stop} - #{data.name}*\n"

    timetable = data.timetable
    |> Enum.map(&to_line/1)
    |> Enum.join("\n")

    keyboard = [["/stop #{stop}", %{text: "refresh 🔄", callback_data: "/stop IL#{stop}"}] | data.timetable
                |> Enum.map(fn r -> r.line end)
                |> Enum.uniq
                |> Enum.sort
                |> Enum.map(fn l -> "/watch #{stop} #{l}" end)
                |> Enum.chunk(3, 3, [])]
                |> Enum.map( fn r ->
      Enum.map(r, &to_button/1)
    end)


    {title <> "```\n#{timetable}```" , @as_markdown ++ [
      {:reply_markup, %{inline_keyboard: keyboard}}
    ]}
  end

  defp send_timetable(data,chat_id, stop) do
    {text, options} = timetable(data, stop)
    {:ok, _} = Nadia.send_message(chat_id, text, options)

    data
  end

  defp send_short_message(chat_id, stop, line) do
    data = Stop.get_info(stop)

    row = data.timetable
    |> Enum.find(fn (row) -> row.line == line end)

    if row == nil || row.time == "Due" do
      Quantum.delete_job(chat_id)
      Logger.info("[#{chat_id}] Remove watch stop #{stop} line #{line}")
    end

    if row != nil do
      Nadia.send_message(chat_id, "```#{row |> to_line}```", @as_markdown)
    end
  end

  defp to_line(%{time: time, line: line, direction: direction}) when line == "Red" or line == "Green" do
    time = String.rjust(time, 9)
    "#{time} | #{direction}"
  end
  defp to_line(%{time: time, line: line, direction: direction}) do
    line = String.rjust(line, 5)
    "#{line} | #{time}"
  end
end
