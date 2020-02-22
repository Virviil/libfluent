defmodule Fluent.Native do
  @moduledoc """
  Module
  """
  use Rustler, otp_app: :libfluent, crate: :fluent_native

  @doc """
  Initializes Fluent native bundle for given `locale`, and returns reference to it on succeded initialization.

  Available options:

  * `use_isolating` - if set to **false**, removes isolation for messages. Can be used in specific environments to prevent unnesessary identation.
    Must be set to **true** in for right-to-left locale usages.

  ## Examples:

      iex> init("en")
      {:ok, #Reference<...>}
  """
  @spec init(locale :: Fluent.locale(), opts :: Keyword.t()) ::
          {:ok, Fluent.bundle()} | no_return()
  def init(_locale, _opts \\ []), do: error()

  @doc """
  Adds new FTL `resource` for existing `bundle`.

  Resource **mast be** valid FTL source. The function can returns `:ok` if `resource` is valid,
  and does not return `bundle` reference again, becuse data under the reference is mutable.

  ## Examples:

      iex> {:ok, bundle} = init("en")
      {:ok, #Reference<...>}

      iex> with_resource(bundle, "key = Translation")
      :ok
  """
  @spec with_resource(bundle :: Fluent.bundle(), resource :: String.t()) ::
          :ok | {:error, :bad_resource} | no_return()
  def with_resource(_bundle, _resource), do: error()

  @doc """
  Performs localization for given `message` with given `bundle`.

  Returns `ok` tuple if message is succeeded
  Potentially can crash in the `bundle` that is given not match.
  """
  @spec format_pattern(bundle :: Fluent.bundle(), message :: String.t(), args :: Keyword.t()) ::
          {:ok, String.t()} | {:error, :bad_msg} | no_return()
  def format_pattern(_bundle, _message, _args), do: error()

  @spec assert_locale(locale :: Fluent.locale()) :: :ok | {:error, any} | no_return
  def assert_locale(locale) when is_binary(locale), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
