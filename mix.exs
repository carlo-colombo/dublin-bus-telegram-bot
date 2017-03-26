defmodule DublinBusTelegramBot.Mixfile do
  use Mix.Project

  def project do
    [app: :dublin_bus_telegram_bot,
     version: "0.6.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [
        :logger,
        :nadia,
        :quantum,
        :maru,
        :edib,
        :httpoison,
        :dublin_bus_api,
        :commander,
        :meter,
        :conform
      ] ++ dev_apps(Mix.env, [:exsync]),
      mod: {DublinBusTelegramBot, [Mix.env]}]
  end


  defp dev_apps(:dev, list), do: list
  defp dev_apps(_, _), do: []

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:nadia, git: "https://github.com/zhyu/nadia", override: true},
     {:quantum, "~> 1.9"},
     {:httpoison, "~> 0.11"},
     {:dublin_bus_api, "~> 0.1"},
     {:maru, "~> 0.9.2" },
     {:exsync, "~> 0.1", only: :dev},
     {:distillery, "~> 1.2"},
     {:edib, "~> 0.7"},
     {:conform, "~> 2.3", override: true},
     {:commander, "~> 1.0"},
     {:meter, "~> 0.1"},
     {:poison, "~> 3.0", override: true},
     {:credo, "~> 0.7", only: [:test, :dev]}
   ]
  end
end
