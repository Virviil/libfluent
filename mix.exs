defmodule Fluent.MixProject do
  use Mix.Project

  @app :libfluent
  @version "0.2.3"
  @native_app :fluent_native

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      description: description(),
      compilers: Mix.compilers(),
      test_coverage: [tool: ExCoveralls],
      docs: docs(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application, do: [extra_applications: [:logger]]

  def description() do
    """
    I18n and L10n Project Fluent implimentation for Elixir.
    """
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler, "~> 0.29.1"},
      {:mix_test_watch, "~> 1.1", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:excoveralls, "~> 0.13", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      logo: "extras/logo.png",
      extras: [
        "README.md"
      ]
    ]
  end

  defp package do
    [
      maintainers: ["Dmitry Rubinstein"],
      licenses: ~w(MIT Apache-2.0),
      links: %{"Github" => "https://github.com/Virviil/libfluent"},
      files: ~w(mix.exs  lib) ++ rust_files()
    ]
  end

  defp rust_files do
    ~w(Cargo.toml src .cargo)
    |> Enum.map(&"native/#{@native_app}/#{&1}")
  end
end
