defmodule RS.Downloader do

  @doc """
  Downloads the file at the given `url` into a Stream and returns it.
  """
  @spec stream!(String.t) :: Stream.t
  def stream!(url) do
    Stream.resource(fn -> begin_download(url) end,
                    &continue_download/1,
                    &finish_download/1)
  end

  @doc false
  def begin_download(url) do
    %HTTPoison.AsyncResponse{id: ref} = HTTPoison.get!(url, %{}, stream_to: self)
    ref
  end

  @doc false
  def continue_download(ref) do
    receive do
      %HTTPoison.AsyncStatus{code: 200, id: ^ref} -> {[], ref}
      %HTTPoison.AsyncStatus{code: _, id: ^ref} -> {:halt, ref}
      %HTTPoison.AsyncChunk{chunk: chunk, id: ^ref} -> {[chunk], ref}
      %HTTPoison.AsyncEnd{id: ^ref} -> {:halt, ref}
    end
  end

  @doc false
  def finish_download(_ref), do: :ok
end
