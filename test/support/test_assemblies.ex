defmodule Assembly.Empty do
  @moduledoc false
  use Fluent.Assembly, otp_app: :libfluent
end

defmodule Assembly.WithPriv do
  @moduledoc false
  use Fluent.Assembly, otp_app: :libfluent, priv: "another-priv-folder"
end

defmodule Assembly.DefaultLanguageChanged do
  @moduledoc false
  use Fluent.Assembly, otp_app: :libfluent, priv: "another-priv-folder"
end
