defmodule TokenValidation do
  use Maru.Middleware

  def call(conn, opts) do
    paths = conn.path_info

    if (Enum.member?(opts[:paths], :hook)
      and hd(paths) != Application.get_env(:nadia, :token)) do
      send_resp(conn, 501, "Invalid token")
    end
    conn
  end
end
