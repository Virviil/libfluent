# NIF for Elixir.Fluent.Native

## To load the NIF:

```elixir
defmodule Fluent.Native do
    use Rustler, otp_app: <otp-app>, crate: "fluent_native"

    # When your NIF is loaded, it will override this function.
    def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
end
```

## Examples

[This](https://github.com/hansihe/NifIo) is a complete example of a NIF written in Rust.
