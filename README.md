# libfluent
[![](https://img.shields.io/hexpm/dt/libfluent.svg?style=flat-square)](https://hex.pm/packages/libfluent)[![](https://img.shields.io/hexpm/v/libfluent.svg?style=flat-square)](https://hex.pm/packages/libfluent)[![](https://img.shields.io/hexpm/l/libfluent.svg?style=flat-square)](https://hex.pm/packages/libfluent)[![](https://img.shields.io/circleci/build/gh/Virviil/libfluent?style=flat-square)](https://circleci.com/gh/Virviil/libfluent)[![](https://img.shields.io/coveralls/github/Virviil/libfluent.svg?style=flat-square)](https://coveralls.io/github/Virviil/libfluent)[![](https://img.shields.io/github/last-commit/virviil/libfluent.svg?style=flat-square)](https://github.com/Virviil/libfluent/commits)[![](https://img.shields.io/maintenance/yes/2019.svg?style=flat-square)](https://github.com/Virviil/libfluent)

Module provides [**Project Fluent**](https://projectfluent.org/) bindings and API to build 
internationalized applications. API is trying to be as simmilar as possible to 
Elixir's *default* internatrionalization library - [**Gettext**](https://hex.pm/packages/gettext)

At the same time, `Fluent.Native` module - as native binding - can be used to work with **Project Fluent**
from any structure of choice. One can use it to define his own API, that is opposite to **Gettext** API
as much as he wants.

## Using Fluent

To use **Fluent**, a module that calls `use Fluent.Assembly` has to be defined:

```elixir
defmodule MyApp.Fluent do
  use Fluent.Assembly, otp_app: :my_app
end
```

This automatically defines some funcitons in the `MyApp.Fluent` module, that can be used to translation:

```elixir
import MyApp.Fluent

# Simple translation
ftl("hello-world")

# Argument-based translation
ftl("hello-user", userName: "Alice")

# With different types
ftl("shared-photos", userName: "Alice", userGender: "female", photoCount: 3)
```

## Translations

Translations are stored inside **FTL** files, with `.ftl` extension. 
Syntax overview can be found [here](https://projectfluent.org/fluent/guide/)

**FTL** files, containgin translations for an application must be stored in a directory (by default it's `priv/fluent`),
that has the following structure:

```bash
%FLUENT_TRANSLATIONS_DIRECTORY%
└─ %LOCALE%
   ├─ file_1.ftl
   ├─ file_2.ftl
   └─ file_3.ftl
```

Here, **%LOCALE%** is the locale of the translations (for example, `en_US`),
and file_i.ftl are FTL files containing translations. All the files from single translation
are loaded as the single scope, so name conflicts inside the files in one folder should be avoided.

A concrete example of such a directory structure could look like this:

```bash
priv/gettext
└─ en_US
|  ├─ default.ftl
|  └─ errors.ftl
└─ it
   ├─ default.ftl
   └─ errors.ftl
```

By default, **Fluent** expects translations to be stored under the `fluent` directory inside `priv` directory of an application. This behaviour can be changed by specifying a `:priv` option when using `Fluent.Assembly`:

```elixir
# Look for translations in my_app/priv/translations instead of
# my_app/priv/gettext
use Fluent.Assembly, otp_app: :my_app, priv: "translations"
```

## Locale

At runtime, all translation functions that do not explicitly take a locale as an argument read the locale from the assembly locale and then fallbacks to `libfluent`'s locale.

`Fluent.put_locale/1` can be used to change the locale of all assemblies for the current Elixir process. That's the preferred mechanism for setting the locale at runtime. `Fluent.put_locale/2` can be used when you want to set the locale of one specific **Fluent** assembly without affecting other **Fluent** assemblies.

Similarly, `Fluent.get_locale/0` gets the locale for all assemblies in the current process. Gettext.get_locale/1 gets the locale of a specific assembly for the current process. Check their documentation for more information.

Locales are expressed as strings (like "en" or "fr"); they can be arbitrary strings as long as they match a directory name. As mentioned above, the locale is stored per-process (in the process dictionary): this means that the locale must be set in every new process in order to have the right locale available for that process. Pay attention to this behaviour, since not setting the locale will not result in any errors when `Fluent.get_locale/0` or `Fluent.get_locale/1` are called; the default locale will be returned instead.

To decide which locale to use, each gettext-related function in a given assembly follows these steps:

* if there is a assembly-specific locale for the given assembly for this process (see `Fluent.put_locale/2`), 
  use that, *otherwise*
* if there is a global locale for this process (see `Fluent.put_locale/1`), 
  use that, *otherwise*
* if there is a assembly's specific default locale in the configuration for that assembly's `:otp_app`
  (see the [**Default locale**](#default-locale) section below), use that, *otherwise*
* use the default global **Fluent** locale (see the [**Default locale**](#default-locale) section below)


### Default locale

The global **Fluent** default locale can be configured through the `:default_locale` key of the `:libfluent` application:

```elixir
config :libfluent, :default_locale, "fr"
```

By default the global locale is "en".

If for some reason an assembly requires with a different `:default_locale` than all other assemblies, you can set the `:default_locale` inside the assembly configuration, but this approach is generally discouraged as it makes it hard to track which locale each assembly is using:

```elixir
config :my_app, MyApp.Fluent, default_locale: "fr"
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `fluent` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:libfluent, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/fluent](https://hexdocs.pm/libfluent).
