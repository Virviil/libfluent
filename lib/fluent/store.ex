defmodule Fluent.Store do
  @moduledoc """
  This module hande references to active bundles, that are using during runtimne
  of the program
  """
  alias Fluent.Assembly.Source

  @behaviour Access
  defstruct bundles: %{}

  @type t :: %__MODULE__{}

  #############################################################################
  ### Access behaviour implementation
  #############################################################################

  @impl Access
  defdelegate fetch(term, key), to: Map

  @impl Access
  defdelegate get_and_update(data, key, function), to: Map

  @impl Access
  defdelegate pop(data, key), to: Map

  #############################################################################
  ### Initialization tree
  #############################################################################

  @spec get_store(assembly :: Fluent.Assembly.t()) :: Fluent.Store.t()
  def get_store(assembly) do
    case :persistent_term.get(assembly, nil) do
      assembly = %__MODULE__{} -> assembly
      _ -> initialize_store(assembly)
    end
  end

  @spec initialize_store(assembly :: Fluent.Assembly.t()) :: {:ok, t()}
  def initialize_store(assembly) do
    assembly
    |> Source.locales()
    |> Enum.each(&initialize_locale(assembly, &1))

    :persistent_term.get(assembly)
  end

  @doc """

  Example:

  iex> Fluent.Store.initialize_bundle(MyApp.Fluent, "en-US")
  """
  @spec initialize_locale(assembly :: Fluent.Assembly.t(), locale :: Fluent.locale()) ::
          {:ok, Fluent.bundle()}
  def initialize_locale(assembly, locale) do
    with {:ok, bundle_ref} when is_reference(bundle_ref) <-
           Fluent.Native.init(locale, use_isolating: assembly.__config__(:use_isolating)),
         :ok <- persist_bundle(assembly, locale, bundle_ref),
         :ok <- add_resources(bundle_ref, assembly, locale) do
      {:ok, bundle_ref}
    end
  end

  @spec format_pattern(Fluent.Store.t(), Fluent.locale(), String.t(), Keyword.t()) :: any
  def format_pattern(store, locale, message, args \\ []) do
    case Map.get(store.bundles, locale) do
      nil -> {:error, :bad_locale}
      bundle -> Fluent.Native.format_pattern(bundle, message, args)
    end
  end

  @spec known_locales(store :: t()) :: [Fluent.locale()]
  def known_locales(store) do
    Map.keys(store[:bundles])
  end

  @spec add_resources(
          bundle_reference :: Fluent.bundle(),
          assembly :: Fluent.Assembly.t(),
          locale :: Fluent.locale()
        ) :: :ok
  defp add_resources(bundle_reference, assembly, locale) do
    assembly
    |> Source.ftl_files_pathes(locale)
    |> Enum.each(fn path ->
      case File.read(path) do
        {:ok, raw_data} -> Fluent.Native.with_resource(bundle_reference, raw_data)
        # May be here is needed to handle errors
        {:error, _} -> :skip_this_file
      end
    end)
  end

  @spec persist_bundle(
          assembly :: Fluent.Assembly.t(),
          locale :: Fluent.locale(),
          bundle_reference :: reference()
        ) :: :ok
  defp persist_bundle(assembly, locale, bundle_reference) do
    store =
      put_in(
        :persistent_term.get(assembly, %__MODULE__{}),
        [:bundles, locale],
        bundle_reference
      )
    :persistent_term.put(assembly, store)
  end
end
