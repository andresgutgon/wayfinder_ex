defmodule Wayfinder.MixProject do
  use Mix.Project

  @version "0.1.6"

  def project do
    [
      app: :wayfinder_ex,
      name: "Wayfinder Ex",
      version: @version,
      description:
        "Wayfinder generates TypeScript client helpers from Phoenix routes for use with Inertia.js or similar frameworks.",
      package: package(),
      elixir: "~> 1.17",
      source_url: links()["GitHub"],
      homepage_url: links()["GitHub"],
      docs: docs(),
      deps: deps(),
      start_permanent: Mix.env() == :prod,
      test_paths: ["test"],
      test_pattern: "*_test.exs",
      test_coverage: [tool: ExCoveralls],
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: [
        plt_add_apps: [:mix],
        ignore_warnings_for: [
          "lib/mix/tasks/generate..ex",
          "lib/mix/tasks/generate_tests.ex"
        ]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def links do
    %{
      "GitHub" => "https://github.com/andresgutgon/wayfinder_ex",
      "Readme" => "https://github.com/andresgutgon/wayfinder_ex/blob/v#{@version}/README.md"
    }
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: [
        "README.md",
        "LICENSE.md"
      ]
    ]
  end

  defp package do
    [
      name: :wayfinder_ex,
      maintainers: ["Andrés Gutiérrez"],
      licenses: ["MIT"],
      links: links(),
      files: ~w(lib assets mix.exs README.md LICENSE.md)
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:phoenix, "~> 1.7", optional: true},
      {:file_system, "~> 1.1.0"},
      {:mock, "~> 0.3.0", only: :test}
    ]
  end
end
