defmodule Fluent.Native do
  use Rustler, otp_app: :libfluent, crate: :fluent_native

  def init(_locale), do: error()
  def with_resource(_bundle, _resource), do: error()
  def format_pattern(_bundle, _message, _args), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
