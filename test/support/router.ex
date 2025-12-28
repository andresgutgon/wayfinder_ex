defmodule TestApp.FakeStrategyRouter do
  @moduledoc """
  A fake router module to simulate AshAuthentication.Phoenix.StrategyRouter
  for testing forward route filtering.
  """
  def init(opts), do: opts
  def call(conn, _opts), do: conn
end

defmodule TestApp.TestRouter do
  use Phoenix.Router

  @moduledoc """
  A simple test router for RoutesWatcher tests.
  This module exists solely to provide a valid router module for testing
  without depending on the workbench or external dependencies.
  """

  get("/test", TestApp.TestController, :index)
  get("/test/:id", TestApp.TestController, :show)
end

defmodule TestApp.TestRouterWithForward do
  use Phoenix.Router

  @moduledoc """
  A test router that includes a forward route to test filtering.
  This simulates routers that use forward for authentication (like AshAuthentication).
  """

  get("/posts", TestApp.TestController, :index)
  get("/posts/:id", TestApp.TestController, :show)

  forward("/auth", TestApp.FakeStrategyRouter,
    path: "/auth",
    as: :auth,
    only: [:github, :google]
  )
end
