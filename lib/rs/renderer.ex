defmodule RS.Renderer do
  require EEx
  EEx.function_from_file :def, :track, "lib/rs/templates/_track.json.eex", [:track, :pretext]
  EEx.function_from_file :def, :status, "lib/rs/templates/_status.json.eex", [:status, :listeners]
  EEx.function_from_file :def, :playlist, "lib/rs/templates/_playlist.json.eex", [:tracks]
  EEx.function_from_file :def, :help, "lib/rs/templates/_help.json.eex"
  EEx.function_from_file :def, :warning, "lib/rs/templates/_warning.json.eex", [:message]
  EEx.function_from_file :def, :error, "lib/rs/templates/_error.json.eex", [:message]

  EEx.function_from_file :def, :response, "lib/rs/templates/response.json.eex", [:attachments]
end
