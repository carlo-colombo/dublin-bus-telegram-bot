defmodule DublinBusTelegramBot.Commands do
  require Logger

  @as_markdown [{:parse_mode, "Markdown"}]
  import DublinBusTelegramBot.Meter

  defmeter start(chat_id) do
    Nadia.send_message(chat_id, "
Welcome to the Dublin Bus bot:

Access to the *Real Time Passenger Information (RTPI)* for Dublin Bus services. Data are retrieved parsing the still-in-development RTPI site. The html could change without notice and break the API, we don't take any responsability for lost bus. The bot is precise as the dublin bus application or the screen at the stops.

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

    ", @as_markdown)
  end

  defmeter stop(chat_id, stop) do
    Stop.get_info(stop)
    |> send_timetable(chat_id, stop)
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

  defmeter search(chat_id, q) do
    data = Stop.search(q)

    case length(data) do
      1 ->
        Nadia.send_message(chat_id, "Search return only 1 result, here is the timetable")
        stop = data |> hd
        send_timetable(stop,chat_id ,stop.ref)
      x ->
        Nadia.send_message(chat_id, "Search return #{x} results")
        message = data
      |> Enum.map(fn(stop) ->
        "** #{stop.ref} - #{stop.name} \n" <> (Enum.map(stop.lines, fn(line) -> "#{elem(line,0)} #{elem(line,1)} " end)
      |> Enum.join("\n")) <> ""
      end)
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

  defp send_timetable(data,chat_id, stop) do
    title = "*#{stop} - #{data.name}*\n"

    timetable = data.timetable
    |> Enum.map(&to_line/1)
    |> Enum.join("\n")

    keyboard = [["/stop #{stop}"] | data.timetable
                 |> Enum.map(fn r -> r.line end)
               |> Enum.uniq
               |> Enum.sort
               |> Enum.map(fn l -> "/watch #{stop} #{l}" end)
               |> Enum.chunk(3, 3, [])]

    Nadia.send_message(chat_id, title <> "```\n#{timetable}```" , @as_markdown ++ [
      {:reply_markup, %{keyboard: keyboard}}])
    data
  end


  defp send_short_message(chat_id, stop, line) do
    data = Stop.get_info(stop)

    row = data.timetable
    |> Enum.find( fn (row) -> row.line == line end )

    if(row == nil || row.time == "Due") do
      Quantum.delete_job(chat_id)
      Logger.info("[#{chat_id}] Remove watch stop #{stop} line #{line}")
    end

    if row != nil do
      Nadia.send_message(chat_id, "```#{row |> to_line}```", @as_markdown)
    end
  end

  defp to_line(%{time: time, line: line}) do
    line = String.rjust(line, 5)
    "#{line} | #{time}"
  end
end
