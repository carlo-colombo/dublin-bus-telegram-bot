defmodule DublinBusTelegramBot.Mixfile do
  use Mix.Project

  def project do
    [app: :dublin_bus_telegram_bot,
     version: "0.4.5",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
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
        :conform,
        :conform_exrm] ++ dev_apps(Mix.env, [:exsync]),
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
    [{:nadia, "~> 0.3"},
     {:quantum, ">= 1.6.1"},
     {:httpoison, "~> 0.8"},
     {:dublin_bus_api, "~> 0.1"},
     {:maru, "~> 0.9.2"},
     {:exsync, "~> 0.1", only: :dev},
     {:exrm, "~> 1.0.3", override: true},
     {:edib, "~> 0.7"},
     {:conform, "~> 2.0", override: true},
     {:conform_exrm, "~> 1.0"},
     {:commander, "~> 0.1"},
     {:meter, "~> 0.1"},
     {:credo, "~> 0.3", only: [:test, :dev]}
    ]
  end
end
