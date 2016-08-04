use Mix.Config

config :porcelain, driver: Porcelain.Driver.Goon

config :rs,
  port: System.get_env("PORT") || "4000",
  hostname: System.get_env("HOSTNAME") || "http://localhost:4000",
  slack_token: System.get_env("SLACK_TOKEN") || "123",
  soundcloud_client_id: System.get_env("SOUNDCLOUD_CLIENT_ID")

# import_config "#{Mix.env}.exs"
