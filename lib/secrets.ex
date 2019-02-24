defmodule TwoFactorInACan.Secrets do
  @moduledoc """
  Functions for generating cryptographic secrets.
  """

  @default_totp_secret_byte_size 20

  @type secret_generation_opts :: keyword(atom() | integer())

  @spec generate_totp_secret(secret_generation_opts) :: binary()
  def generate_totp_secret(opts \\ []) do
    @default_totp_secret_byte_size
    |> :crypto.strong_rand_bytes()
    |> format_secret(opts)
  end

  @spec format_secret(binary(), secret_generation_opts) :: binary()
  defp format_secret(secret, opts) do
    format = Keyword.get(opts, :format, :binary)

    case format do
      :binary -> secret
      :base32 -> Base.encode32(secret)
      :base64 -> Base.encode64(secret)
    end
  end
end
