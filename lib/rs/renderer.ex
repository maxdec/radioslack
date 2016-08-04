defmodule RS.Renderer do
  require EEx
  EEx.function_from_file :def, :track, "lib/rs/templates/track.json.eex", [:track, :title]
  EEx.function_from_file :def, :status, "lib/rs/templates/status.json.eex", [:current, :listeners]
  EEx.function_from_file :def, :warning, "lib/rs/templates/warning.json.eex", [:message]
  EEx.function_from_file :def, :error, "lib/rs/templates/error.json.eex", [:message]
  EEx.function_from_file :def, :playlist, "lib/rs/templates/playlist.json.eex", [:playlist]
  EEx.function_from_file :def, :help, "lib/rs/templates/help.json.eex"
end
