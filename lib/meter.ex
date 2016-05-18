defmodule DublinBusTelegramBot.Meter do
  use Logger

  def log(command, kwargs) do
    Logger.info("inspect #{command}(#{inspect(kwargs)})")

    env = Application.get_all_env(:dublin_bus_telegram_bot)

    tid = env[:google_analytics]
    mapping = env[:ga_mapping]
    dimensions = env[:ga_dimensions]

    if tid != nil do
      cd = 1..3
      |> Enum.map(fn i -> "cd#{i}" end)
      |> Enum.zip(dimensions)
      |> Enum.map(fn {cdi,argname} -> {cdi, kwargs[argname]} end )

      body = {:form, [
                 v: 1,
                 cid: kwargs[mapping[:cid]],
                 tid: tid,
                 t: "pageview",
                 ds: "bot",
                 dp: command
               ] ++ cd}

      spawn fn ->
        case HTTPoison.post("https://www.google-analytics.com/collect", body) do
          {:ok, resp} -> IO.puts("sent #{inspect(resp)}")
          {:error, error} -> IO.puts("Error #{inspect(error)}")
        end
      end
    end
  end

  defp get_body({:ok,
                 %HTTPoison.Response{status_code: 200,
                                     body: body}}) do
    {:ok, body}
  end


  defmacro defmeter({function,_,args}=fundef, [do: body]) do
    names = args
    |> Enum.map(fn {arg_name, _,_} -> arg_name end)

    metered = {:__block__, [],
               [quote do
                 values= unquote(
                   args
                   |> Enum.map(fn arg ->  quote do
                       var!(unquote(arg))
                     end
                   end)
                 )
                 map = Enum.zip(unquote(names), values)
                 log(unquote(function), map)
               end, body]}

    quote do
      def(unquote(fundef),unquote([do: metered]))
    end
  end
end
