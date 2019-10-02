defmodule Fluent do
  @typedoc """
  Represents locale. Basically it's a string, that has valid locale identifier
  """
  @type locale :: String.t()

  @typedoc """
  Native container, that is firstly identified and then used for translations
  """
  @type bundle :: reference()
end
