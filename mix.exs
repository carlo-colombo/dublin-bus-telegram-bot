defmodule DublinBusTelegramBot.Mixfile do
  use Mix.Project

  def project do
    [app: :dublin_bus_telegram_bot,
     version: "0.1.1",
     elixir: "~> 1.1",
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
        :dublin_bus_api,
        :commander,
        :conform,
        :conform_exrm] ++ dev_apps(Mix.env, [:exsync]),
    mod: {DublinBusTelegramBot, []}]
  end


  defp dev_apps(:prod, _), do: []
  defp dev_apps(_, list), do: list

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
     {:dublin_bus_api, "~> 0.1"},
     {:maru, "~> 0.9.2"},
     {:exsync, "~> 0.1", only: :dev},
     {:exrm, "~> 1.0.3", override: true},
     {:edib, git: "https://github.com/edib-tool/mix-edib"},
     {:conform, "~> 2.0", override: true},
     {:conform_exrm, "~> 1.0"},
     {:commander, "~> 0.1"}
    ]
  end
end
