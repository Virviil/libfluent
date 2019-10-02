defmodule Fluent.Assembly do
  @type t :: atom()

  @doc """
  Doc for using macro

  opts:

  * otp_app: "libfluen"
  * priv: "priv/fluent"
  * default_locale: "en-US"
  """
  defmacro __using__(opts) do
    quote location: :keep do
      @otp_app Keyword.fetch!(unquote(opts), :otp_app)
      @priv Keyword.get(unquote(opts), :priv, "fluent")
      @default_locale Keyword.get(unquote(opts), :default_locale, "en")
      @silent_errors Keyword.get(unquote(opts), :silent_errors, false)

      @spec __config__(atom()) :: any()
      def __config__(:otp_app), do: @otp_app
      def __config__(:sys), do: Application.get_env(@otp_app, __MODULE__, [])
      def __config__(:priv), do: Keyword.get(__config__(:sys), :priv, nil) || @priv
      def __config__(:default_locale), do: Keyword.get(__config__(:sys), :default_locale, nil) || @default_locale
      def __config__(:silent_errors), do: Keyword.get(__config__(:sys), :silent_errors, nil) || @silent_errors

      @spec __store__() :: Fluent.Store.t()
      def __store__ do
        Fluent.Store.get_store(__MODULE__)
      end

      def ftl(message, args \\ []) do
        locale = Fluent.Assembly.get_locale(__MODULE__)
        case Fluent.Store.format_pattern(__store__(), locale, message, args) do
          {:ok, message} -> message
          _ -> case __config__(:silent_errors) do
            true -> message
            false -> raise(
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

  @doc """
  Sets the global Fluent locale for the current process.
  The locale is stored in the process dictionary. `locale` must be a string; if
  it's not, an `ArgumentError` exception is raised.
  ## Examples
      Fluent.put_locale("pt_BR")
      #=> nil
      Fluent.get_locale()
      #=> "pt_BR"
  """
  @type locale :: binary
  @type assembly :: module

  @spec put_locale(locale) :: nil
  def put_locale(locale) when is_binary(locale), do: Process.put(Fluent.Assembly, locale)

  def put_locale(locale),
    do: raise(ArgumentError, "put_locale/1 only accepts binary locales, got: #{inspect(locale)}")

  @doc """
  Gets the locale for the current process and the given assembly.
  This function returns the value of the locale for the current process and the
  given `assembly`. If there is no locale for the current process and the given
  assembly, then either the global Fluent locale (if set), or the default locale
  for the given assembly, or the global default locale is returned. See the
  "Locale" section in the module documentation for more information.
  ## Examples
      Fluent.get_locale(MyApp.Fluent)
      #=> "en"
  """
  @spec get_locale(assembly) :: locale
  def get_locale(assembly) do
    Process.get(assembly) || Process.get(Fluent.Assembly) || assembly.__config__(:default_locale)
  end

  @doc """
  Sets the locale for the current process and the given `assembly`.
  The locale is stored in the process dictionary. `locale` must be a string; if
  it's not, an `ArgumentError` exception is raised.
  ## Examples
      Fluent.put_locale(MyApp.Fluent, "pt_BR")
      #=> nil
      Fluent.get_locale(MyApp.Fluent)
      #=> "pt_BR"
  """
  @spec put_locale(assembly, locale) :: nil
  def put_locale(assembly, locale) when is_binary(locale), do: Process.put(assembly, locale)

  def put_locale(_assembly, locale),
    do: raise(ArgumentError, "put_locale/2 only accepts binary locales, got: #{inspect(locale)}")

  @doc """
  Runs `fun` with the global Fluent.Assembly locale set to `locale`.
  This function just sets the global Fluent.Assembly locale to `locale` before running
  `fun` and sets it back to its previous value afterwards. Note that
  `put_locale/2` is used to set the locale, which is thus set only for the
  current process (keep this in mind if you plan on spawning processes inside
  `fun`).
  The value returned by this function is the return value of `fun`.
  ## Examples
      Fluent.Assembly.put_locale("fr")
      MyApp.Fluent.Assembly.Fluent.Assembly("Hello world")
      #=> "Bonjour monde"
      Fluent.Assembly.with_locale "it", fn ->
        MyApp.Fluent.Assembly.Fluent.Assembly("Hello world")
      end
      #=> "Ciao mondo"
      MyApp.Fluent.Assembly.Fluent.Assembly("Hello world")
      #=> "Bonjour monde"
  """
  @spec with_locale(locale, (() -> result)) :: result when result: var
  def with_locale(locale, fun) do
    previous_locale = Process.get(Fluent.Assembly)
    Fluent.Assembly.put_locale(locale)

    try do
      fun.()
    after
      if previous_locale do
        Fluent.Assembly.put_locale(previous_locale)
      else
        Process.delete(Fluent.Assembly)
      end
    end
  end

  @doc """
  Runs `fun` with the Fluent.Assembly locale set to `locale` for the given `assembly`.
  This function just sets the Fluent.Assembly locale for `assembly` to `locale` before
  running `fun` and sets it back to its previous value afterwards. Note that
  `put_locale/2` is used to set the locale, which is thus set only for the
  current process (keep this in mind if you plan on spawning processes inside
  `fun`).
  The value returned by this function is the return value of `fun`.
  ## Examples
      Fluent.Assembly.put_locale(MyApp.Fluent.Assembly, "fr")
      MyApp.Fluent.Assembly.Fluent.Assembly("Hello world")
      #=> "Bonjour monde"
      Fluent.Assembly.with_locale MyApp.Fluent.Assembly, "it", fn ->
        MyApp.Fluent.Assembly.Fluent.Assembly("Hello world")
      end
      #=> "Ciao mondo"
      MyApp.Fluent.Assembly.Fluent.Assembly("Hello world")
      #=> "Bonjour monde"
  """
  @spec with_locale(assembly, locale, (() -> result)) :: result when result: var
  def with_locale(assembly, locale, fun) do
    previous_locale = Process.get(assembly)
    Fluent.Assembly.put_locale(assembly, locale)

    try do
      fun.()
    after
      if previous_locale do
        Fluent.Assembly.put_locale(assembly, previous_locale)
      else
        Process.delete(assembly)
      end
    end
  end

  @doc """
  Returns all the locales for which PO files exist for the given `assembly`.
  If the translations directory for the given assembly doesn't exist, then an
  empty list is returned.
  ## Examples
  With the following assembly:
      defmodule MyApp.Fluent.Assembly do
        use Fluent.Assembly, otp_app: :my_app
      end
  and the following translations directory:
      my_app/priv/Fluent.Assembly
      ├─ en
      ├─ it
      └─ pt_BR
  then:
      Fluent.Assembly.known_locales(MyApp.Fluent)
      #=> ["en", "it", "pt_BR"]
  """
  @spec known_locales(assembly) :: [locale]
  def known_locales(assembly) do
    Fluent.Store.known_locales(assembly.__store__())
  end
end
