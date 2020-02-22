defmodule Fluent.Assembly do
  @moduledoc """
  Module
  """
  @type t :: atom()

  @doc """
  Doc for using macro

  opts:

  * otp_app: "libfluen"
  * priv: "priv/fluent"
  * default_locale: "en-US"
  * use_isolating: false - default is true
  """
  defmacro __using__(opts) do
    quote location: :keep do
      @otp_app Keyword.fetch!(unquote(opts), :otp_app)
      @priv Keyword.get(unquote(opts), :priv, "fluent")
      @default_locale Keyword.get(unquote(opts), :default_locale, "en")
      @silent_errors Keyword.get(unquote(opts), :silent_errors, false)
      @use_isolating Keyword.get(unquote(opts), :use_isolating, true)

      @spec __config__(atom()) :: any()
      def __config__(:otp_app), do: @otp_app
      def __config__(:sys), do: Application.get_env(@otp_app, __MODULE__, [])
      def __config__(:priv), do: Keyword.get(__config__(:sys), :priv, nil) || @priv

      def __config__(:default_locale),
        do: Keyword.get(__config__(:sys), :default_locale, nil) || @default_locale

      def __config__(:silent_errors),
        do: Keyword.get(__config__(:sys), :silent_errors, nil) || @silent_errors

      def __config__(:use_isolating),
        do: Keyword.get(__config__(:sys), :use_isolating, nil) || @use_isolating

      @spec __store__() :: Fluent.Store.t()
      def __store__ do
        Fluent.Store.get_store(__MODULE__)
      end

      def ftl(message, args \\ []) do
        locale = Fluent.get_locale(__MODULE__)

        case Fluent.Store.format_pattern(__store__(), locale, message, args) do
          {:ok, message} ->
            message

          _ ->
            case __config__(:silent_errors) do
              true ->
                message

              false ->
                raise(
                  Fluent.MessageNotFound,
                  msg: message,
                  locale: locale,
                  assembly: __MODULE__
                )
            end
        end
      end
    end
  end
end
