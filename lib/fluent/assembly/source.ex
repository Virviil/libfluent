defmodule Fluent.Assembly.Source do
  @moduledoc """
  Module
  """

  @doc """
  Returns absolute path to directory, which contains all FTL data for `assembly`.

  ## Examples:

      iex> assembly_dir(MyApp.Fluent)
      "/path/to/ftl/files/"
  """
  @spec assembly_dir(assembly :: Fluent.Assembly.t()) :: Path.t()
  def assembly_dir(assembly) do
    assembly.__config__(:otp_app)
    |> :code.priv_dir()
    |> Path.join(assembly.__config__(:priv))
  end

  @doc """
  Returns absolute path to directory, which contains all FTL data for `assembly` with given `locale`.

  ## Examples:

      iex> assembly_dir(MyApp.Fluent, "en-US")
      "/path/to/ftl/files/en-US"
  """
  @spec locale_dir(assembly :: Fluent.Assembly.t(), locale :: Fluent.locale()) :: Path.t()
  def locale_dir(assembly, locale) do
    Path.join(assembly_dir(assembly), locale)
  end

  @doc """
  Returns list of all available locales for given `assembly`

  ## Examples:

      iex> locales(MyApp.Fluent)
      ["en", "fr", "ru"]
  """
  @spec locales(assembly :: Fluent.Assembly.t()) :: [Fluent.locale()]
  def locales(assembly) do
    # Caching not to call twise
    assembly_dir = assembly_dir(assembly)

    assembly_dir
    |> Path.join("*")
    |> Path.wildcard()
    |> Enum.map(&Path.relative_to(&1, assembly_dir))
  end

  @doc """
  Returns absolute pathes to all FTL files for given `assembly` and it's `locale`.

  ## Examples:

      iex> ftl_files_pathes(MyApp.Fluent, "en")
      ["/path/to/ftl/1.ftl", "/path/to/ftl/2.frl", ... "/path/to/ftl/last.ftl"]
  """
  @spec ftl_files_pathes(assembly :: Fluent.Assembly.t(), locale :: Fluent.locale()) :: [Path.t()]
  def ftl_files_pathes(assembly, locale) do
    locale_dir(assembly, locale)
    |> Path.join("*.ftl")
    |> Path.wildcard()
  end
end
