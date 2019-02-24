defmodule TwoFactorInACan.Secrets do
  @default_totp_secret_byte_size 20

  @spec generate_totp_secret(keyword(atom() | integer())) :: binary()
  def generate_totp_secret(opts \\ []) do
    @default_totp_secret_byte_size
    |> :crypto.strong_rand_bytes()
    |> format_secret(opts)
  end

  defp format_secret(secret, opts) do
    format = Keyword.get(opts, :format, :binary)

    case format do
      :binary -> secret
      :base32 -> Base.encode32(secret)
      :base64 -> Base.encode64(secret)
    end
  end
end
