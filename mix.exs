defmodule Fluent.MixProject do
  use Mix.Project

  @app :libfluent
  @version "0.1.0"
  @native_app :fluent_native

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      rustler_crates: rustler_crates(),
      package: package(),
      description: description(),
      compilers: [:rustler] ++ Mix.compilers
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application, do: [extra_applications: [:logger]]

  def description() do
    """
    I10n and L18n Project Fluent implimentation for Elixir.
    """
  end

  defp rustler_crates() do
    [fluent_native: [
      path: "native/fluent_native",
      mode: rustc_mode(Mix.env)
    ]]
  end

  defp rustc_mode(:prod), do: :release
  defp rustc_mode(_), do: :debug

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler, "~> 0.21.0"},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev},
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
