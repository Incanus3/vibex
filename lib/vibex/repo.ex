defmodule Vibex.Repo do
  use Ecto.Repo,
    otp_app: :vibex,
    adapter: Ecto.Adapters.Postgres
end
