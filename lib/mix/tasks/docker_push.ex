defmodule Mix.Tasks.DockerPush do
  use Mix.Task

  alias DublinBusTelegramBot.Mixfile
  alias Mix.Tasks

  def run(_args) do
    Edib.run(["--hex", "--strip"])

    project = Enum.into(Mixfile.project, %{})

    for cmd <- commands(project)  do
      Mix.Shell.IO.cmd(cmd, [])
    end
  end

  defp commands(%{version: version}) do
    [
      "docker tag local/dublin_bus_telegram_bot:#{version} carlocolombo/dublin_bus_telegram_bot:latest",
      "docker tag local/dublin_bus_telegram_bot:#{version} carlocolombo/dublin_bus_telegram_bot:#{version}",
      "docker push carlocolombo/dublin_bus_telegram_bot:#{version}",
      "docker push carlocolombo/dublin_bus_telegram_bot:latest"
    ]
  end
end
