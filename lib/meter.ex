defmodule DublinBusTelegramBot.Meter do
  require Logger

  def track(function_name, kwargs) do
    env = Application.get_all_env(:dublin_bus_telegram_bot)

    tid = env[:google_analytics]
    mapping = env[:ga_mapping]
    dimensions = env[:ga_dimensions]

    if tid != nil do
      Logger.info("Tracking inspect #{function_name}(#{inspect(kwargs)})")

      cd = 1..length(dimensions)
      |> Enum.map(fn i -> "cd#{i}" end)
      |> Enum.zip(dimensions)
      |> Enum.map(fn {cdi,argname} -> {cdi, kwargs[argname]} end )

      body = {:form, [
                 v: 1,
                 cid: kwargs[mapping[:cid]],
                 tid: tid,
                 t: "pageview",
                 ds: "bot",
                 dp: "/#{function_name}"
               ] ++ cd}

      Logger.info("form #{inspect(body)}")

      spawn fn ->
        case HTTPoison.post("https://www.google-analytics.com/collect", body) do
          {:ok, resp} -> Logger.info("sent #{inspect(resp)}")
          {:error, error} -> Logger.warn("Error #{inspect(error)}")
        end
      end
    end
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
                 track(unquote(function), map)
               end, body]}

    quote do
      def(unquote(fundef),unquote([do: metered]))
    end
  end
end
