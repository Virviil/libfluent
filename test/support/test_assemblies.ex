defmodule Assembly.Empty do
  use Fluent.Assembly, otp_app: :libfluent
end

defmodule Assembly.WithPriv do
  use Fluent.Assembly, otp_app: :libfluent, priv: "another-priv-folder"
end

defmodule Assembly.DefaultLanguageChanged do
  use Fluent.Assembly, otp_app: :libfluent, priv: "another-priv-folder"
end
