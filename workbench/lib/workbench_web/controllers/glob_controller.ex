defmodule WorkbenchWeb.GlobController do
  use WorkbenchWeb, :controller

  def show(conn, _params), do: send_resp(conn, 200, "ok")
end
