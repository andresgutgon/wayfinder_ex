defmodule Wayfinder.RoutesWatcherTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog

  alias Wayfinder.RoutesWatcher

  defmodule MyTestGenerator do
    def generate(_router, _otp_app), do: :ok
  end

  @router_module TestApp.TestRouter

  setup do
    if Process.whereis(RoutesWatcher) do
      GenServer.stop(RoutesWatcher, :normal, 1000)
    end

    Application.put_env(:wayfinder_ex, :router, @router_module)
    Application.put_env(:wayfinder_ex, :otp_app, :test_app)
    :ok
  end

  describe "child_spec/1" do
    test "returns correct child specification" do
      opts = [some: :option]
      spec = RoutesWatcher.child_spec(opts)

      assert spec.id == RoutesWatcher
      assert spec.start == {RoutesWatcher, :start_link, [opts]}
      assert spec.type == :worker
      assert spec.restart == :permanent
      assert spec.shutdown == 500
    end
  end

  describe "start_link/1" do
    test "starts the GenServer successfully" do
      assert {:ok, pid} = RoutesWatcher.start_link(generator_module: MyTestGenerator)
      assert Process.alive?(pid)

      GenServer.stop(pid)
    end

    test "accepts GenServer options" do
      opts = [debug: [:trace], generator_module: MyTestGenerator]
      assert {:ok, pid} = RoutesWatcher.start_link(opts)
      assert Process.alive?(pid)

      GenServer.stop(pid)
    end
  end

  describe "file event handling" do
    setup context do
      {:ok, calls} = Agent.start_link(fn -> [] end)

      compiler_fun = fn path ->
        Agent.update(calls, &[path | &1])
        :ok
      end

      {:ok, pid} =
        RoutesWatcher.start_link(generator_module: MyTestGenerator, compiler_fun: compiler_fun)

      {:ok, Map.put(context, :watcher_pid, pid) |> Map.put(:calls, calls)}
    end

    test "ignores non-router file modifications", %{watcher_pid: watcher_pid} do
      non_router_path = "/path/to/controller.ex"
      events = [:modified]

      log =
        capture_log(fn ->
          send(watcher_pid, {:file_event, :mock_watcher, {non_router_path, events}})
          GenServer.call(watcher_pid, :ping, 1000)
        end)

      refute log =~ "[wayfinder] routes re-generated"
    end

    test "ignores router file events that are not modifications", %{watcher_pid: watcher_pid} do
      router_path = "/path/to/router.ex"
      events = [:created, :deleted]

      log =
        capture_log(fn ->
          send(watcher_pid, {:file_event, :mock_watcher, {router_path, events}})
          GenServer.call(watcher_pid, :ping, 1000)
        end)

      refute log =~ "[wayfinder] routes re-generated"
    end

    test "handles stop events gracefully", %{watcher_pid: watcher_pid} do
      send(watcher_pid, {:file_event, :mock_watcher, :stop})
      GenServer.call(watcher_pid, :ping, 1000)
      assert Process.alive?(watcher_pid)
    end

    test "handles unknown events gracefully", %{watcher_pid: watcher_pid} do
      send(watcher_pid, {:unknown_event, :some_data})
      GenServer.call(watcher_pid, :ping, 1000)
      assert Process.alive?(watcher_pid)
    end

    test "calls compiler_function when router.ex is modified", %{
      watcher_pid: watcher_pid,
      calls: calls
    } do
      router_path = "./test/support/router.ex"

      capture_log(fn ->
        send(watcher_pid, {:file_event, :mock_watcher, {router_path, [:modified]}})
        GenServer.call(watcher_pid, :ping, 1000)
      end)

      assert Agent.get(calls, & &1) == [router_path]
    end
  end

  describe "file path detection" do
    setup context do
      # Dummy compiler fun for tests in this block
      compiler_fun = fn _path -> :ok end

      {:ok, pid} =
        RoutesWatcher.start_link(generator_module: MyTestGenerator, compiler_fun: compiler_fun)

      {:ok, Map.put(context, :watcher_pid, pid)}
    end

    test "correctly identifies router.ex files", %{watcher_pid: watcher_pid} do
      router_path = "./test/support/router.ex"

      log =
        capture_log(fn ->
          send(watcher_pid, {:file_event, :mock_watcher, {router_path, [:modified]}})
          GenServer.call(watcher_pid, :ping, 1000)
        end)

      assert log =~ "[wayfinder] routes re-generated"
    end

    test "ignores files that don't match router.ex pattern", %{watcher_pid: watcher_pid} do
      non_router_paths = [
        "/app/lib/app_web/router_helper.ex",
        "/app/lib/app_web/my_router.ex",
        "/app/lib/app_web/admin_router.ex",
        "/app/lib/app_web/controller.ex",
        "/app/lib/app_web/view.ex"
      ]

      for path <- non_router_paths do
        log =
          capture_log(fn ->
            send(watcher_pid, {:file_event, :mock_watcher, {path, [:modified]}})
            GenServer.call(watcher_pid, :ping, 1000)
          end)

        refute log =~ "[wayfinder] routes re-generated"
      end
    end
  end

  describe "router module configuration" do
    setup context do
      compiler_fun = fn _path -> :ok end

      {:ok, pid} =
        RoutesWatcher.start_link(generator_module: Wayfinder, compiler_fun: compiler_fun)

      {:ok, Map.put(context, :watcher_pid, pid)}
    end

    test "handles missing router configuration gracefully", %{watcher_pid: watcher_pid} do
      Application.delete_env(:wayfinder_ex, :router)
      Application.delete_env(:wayfinder_ex, :otp_app)

      router_path = "/path/to/router.ex"
      events = [:modified]

      log =
        capture_log(fn ->
          send(watcher_pid, {:file_event, :mock_watcher, {router_path, events}})
          GenServer.call(watcher_pid, :ping, 1000)
        end)

      assert log =~ "[wayfinder-error]"
    end
  end
end
