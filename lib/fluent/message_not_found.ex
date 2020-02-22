defmodule Fluent.MessageNotFound do
  defexception [:message, :msg, :locale, :assembly]

  @impl Exception
  def exception(error) do
    %__MODULE__{
      message:
        "Translation for message #{Keyword.get(error, :msg)} is not found in #{
          Keyword.get(error, :assembly)
        } assembly for #{Keyword.get(error, :locale)} locale."
    }
  end
end
