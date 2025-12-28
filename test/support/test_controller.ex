defmodule TestApp.TestController do
  import Plug.Conn

  @moduledoc """
  A simple test controller for TestRouter.
  """

  def init(opts), do: opts

  def index(conn, _params), do: send_resp(conn, 200, "ok")
  def show(conn, _params), do: send_resp(conn, 200, "ok")
end
