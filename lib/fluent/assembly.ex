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
  Gets the locale for the current process and the given backend.
  This function returns the value of the locale for the current process and the
  given `assembly`. If there is no locale for the current process and the given
  assembly, then either the global Fluent locale (if set), or the default locale
  for the given backend, or the global default locale is returned. See the
  "Locale" section in the module documentation for more information.
  ## Examples
      Fluent.get_locale(MyApp.Fluent)
      #=> "en"
  """
  @spec get_locale(assembly) :: locale
  def get_locale(assembly) do
    Process.get(assembly) || Process.get(Fluent.Assembly) || assembly.__gettext__(:default_locale)
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
  Runs `fun` with the global Gettext locale set to `locale`.
  This function just sets the global Gettext locale to `locale` before running
  `fun` and sets it back to its previous value afterwards. Note that
  `put_locale/2` is used to set the locale, which is thus set only for the
  current process (keep this in mind if you plan on spawning processes inside
  `fun`).
  The value returned by this function is the return value of `fun`.
  ## Examples
      Gettext.put_locale("fr")
      MyApp.Gettext.gettext("Hello world")
      #=> "Bonjour monde"
      Gettext.with_locale "it", fn ->
        MyApp.Gettext.gettext("Hello world")
      end
      #=> "Ciao mondo"
      MyApp.Gettext.gettext("Hello world")
      #=> "Bonjour monde"
  """
  @spec with_locale(locale, (() -> result)) :: result when result: var
  def with_locale(locale, fun) do
    previous_locale = Process.get(Gettext)
    Gettext.put_locale(locale)

    try do
      fun.()
    after
      if previous_locale do
        Gettext.put_locale(previous_locale)
      else
        Process.delete(Gettext)
      end
    end
  end

  @doc """
  Runs `fun` with the gettext locale set to `locale` for the given `backend`.
  This function just sets the Gettext locale for `backend` to `locale` before
  running `fun` and sets it back to its previous value afterwards. Note that
  `put_locale/2` is used to set the locale, which is thus set only for the
  current process (keep this in mind if you plan on spawning processes inside
  `fun`).
  The value returned by this function is the return value of `fun`.
  ## Examples
      Gettext.put_locale(MyApp.Gettext, "fr")
      MyApp.Gettext.gettext("Hello world")
      #=> "Bonjour monde"
      Gettext.with_locale MyApp.Gettext, "it", fn ->
        MyApp.Gettext.gettext("Hello world")
      end
      #=> "Ciao mondo"
      MyApp.Gettext.gettext("Hello world")
      #=> "Bonjour monde"
  """
  @spec with_locale(backend, locale, (() -> result)) :: result when result: var
  def with_locale(backend, locale, fun) do
    previous_locale = Process.get(backend)
    Gettext.put_locale(backend, locale)

    try do
      fun.()
    after
      if previous_locale do
        Gettext.put_locale(backend, previous_locale)
      else
        Process.delete(backend)
      end
    end
  end

  @doc """
  Returns all the locales for which PO files exist for the given `backend`.
  If the translations directory for the given backend doesn't exist, then an
  empty list is returned.
  ## Examples
  With the following backend:
      defmodule MyApp.Gettext do
        use Gettext, otp_app: :my_app
      end
  and the following translations directory:
      my_app/priv/gettext
      ├─ en
      ├─ it
      └─ pt_BR
  then:
      Gettext.known_locales(MyApp.Gettext)
      #=> ["en", "it", "pt_BR"]
  """
  @spec known_locales(backend) :: [locale]
  def known_locales(backend) do
    backend.__gettext__(:known_locales)
  end
end
