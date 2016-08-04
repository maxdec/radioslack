defmodule RS.Matcher do
  @doc """
  Returns true if the url corresponds to the track type, false otherwise.
  """
  @callback match?(String.t) :: true|false
end
