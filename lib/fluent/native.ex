defmodule Fluent.Native do
  use Rustler, otp_app: :fluent, crate: :fluent_native

  def open(_options), do: error()
  def read_until(_resource, _byte), do: error()

  def init(_locale), do: error()
  def with_resource(_bundle, _resource), do: error()
  def format_pattern(_bundle, _msg, _args), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
