defmodule Wayfinder.ProcessorTest do
  use ExUnit.Case, async: true

  alias Wayfinder.Processor

  describe "call/1" do
    test "filters out forward routes with non-atom plug_opts" do
      {:ok, controllers} = Processor.call(TestApp.TestRouter)

      assert length(controllers) == 1
      assert hd(controllers).module == TestApp.TestController
    end
  end

  describe "valid route filtering" do
    test "accepts routes where plug and plug_opts are both atoms" do
      {:ok, controllers} = Processor.call(TestApp.TestRouterWithForward)

      controller_modules = Enum.map(controllers, & &1.module)

      assert TestApp.TestController in controller_modules
      refute TestApp.FakeStrategyRouter in controller_modules
    end

    test "filters out forward routes with keyword list plug_opts" do
      {:ok, controllers} = Processor.call(TestApp.TestRouterWithForward)

      all_routes = Enum.flat_map(controllers, & &1.routes)

      refute Enum.any?(all_routes, fn route -> route.path == "/auth" end)
    end
  end
end
