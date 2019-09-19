defmodule Fluent.Assembly do
  defmacro __using__(opts) do
    quote location: :keep do
      def t(message, args) do

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
    Process.get(assembly) || Process.get(Fluent.Assembly) || assembly.__fluent__(:default_locale)
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
    assembly.__fluent__(:known_locales)
  end
end
