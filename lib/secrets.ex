defmodule TwoFactorInACan.Secrets do
  @moduledoc """
  Functions for generating cryptographic secrets.
  """

  @type secret_generation_opts :: keyword(atom() | integer())

  @default_totp_secret_byte_size 20

  @doc """
  Generates a secret suitable for use in time based one time password (TOTP)
  two factor authentication.

  Generates a 160-bit key which is the size recommended by RFC4226
  (https://www.ietf.org/rfc/rfc4226.txt).

  By default, outputs a raw binary key with no encoding. The `:format` key can
  be used to specify alternate output formats. Valid formats include:
  - `:binary` (default)
  - `:base32`
  - `:base64`

  # Examples

      iex> TwoFactorInACan.Secrets.generate_totp_secret()
      <<195, 110, 253, 36, 185, 138, 174, 16, 54, 176, 135, 67, 97, 11, 159, 63, 75, 80, 65, 6>>

      iex> TwoFactorInACan.Secrets.generate_totp_secret(format: :base32)
      "F2EJJEYSJA67QHI6DEAI2I6AGCEG7G5E"

      iex> TwoFactorInACan.Secrets.generate_totp_secret(format: :base64)
      "xKXOSYcRVlHfnazLMlRinpb252U="
  """
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
      _ -> raise ArgumentError, """
        Invalid format supplied when generating secret: #{format}

        Valid options include:
        - :binary
        - :base32
        - :base64
        """
    end
  end
end
