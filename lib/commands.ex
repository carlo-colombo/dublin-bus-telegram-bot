defmodule DublinBusTelegramBot.Commands do
  require Logger

  @as_markdown [{:parse_mode, "Markdown"}]

  def stop(chat_id, stop) do
    Stop.get_info(stop)
    |> send_timetable(chat_id, stop)
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

  def watch(chat_id, stop, line) do
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

  def unwatch(chat_id) do
    Quantum.delete_job(chat_id)
    %{}
  end

  def search(chat_id, q) do
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

  def not_implemented(chat_id, command) do
    Nadia.send_message(chat_id, "Not yet implemented")

    warn = "#{command} not yet implemented"
    |> Logger.warn

    %{warn: warn}
  end

  defp to_line(%{time: time, line: line}) do
    line = String.rjust(line, 5)
    "#{line} | #{time}"
  end
end
