use Mix.Releases.Config,
    # This sets the default release built by `mix release`
    default_release: :default,
    # This sets the default environment used by `mix release`
    default_environment: :dev

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/configuration.html


# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :"t,?t*n35oDQ3(<>C)5=-^shUb`s]E~rRb3C9/I[5e0DK-Y.T^{pBy7@BUw-*=]+B"
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"t,?t*n35oDQ3(<>C)5=-^shUb`s]E~rRb3C9/I[5e0DK-Y.T^{pBy7@BUw-*=]+B"
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

conform_prestart = Path.join(["#{:code.priv_dir(:conform)}",
                             "bin",
                             "pre_start.sh"])

release :dublin_bus_telegram_bot do
  set version: current_version(:dublin_bus_telegram_bot)
  set pre_start_hook: conform_prestart
  plugin Conform.ReleasePlugin
end

