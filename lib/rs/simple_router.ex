defmodule RS.SimpleRouter do
  defmacro __using__(_opts) do
    quote do
      use Plug.Builder
      def init(options) do
        options
      end
      def call(conn, opts) do
        conn = super(conn, opts)
        path = Enum.join(conn.path_info, "/")
        route(conn.method, "/#{path}", conn, opts)
      end
    end
  end
end
