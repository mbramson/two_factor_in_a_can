defmodule TwoFactorInACan.Totp do
  @moduledoc """
  Functions for working with time based one time password (TOTP) style two
  factory authentication as defined in RFC4226
  (https://www.ietf.org/rfc/rfc4226.txt).
  """

  @doc """
  Outputs the current TOTP token for the given secret.

  Expects a 160-bit binary key by default. To use secrets that are encoded the
  `:secret_format` option can be supplied. It expects one of the following
  values:
  - `:binary` (default)
  - `:base32`
  - `:base64`

  # Examples

  iex> secret = TwoFactorInACan.Secrets.generate_totp_secret()
  iex> TwoFactorInACan.Totp.current_token_value(secret)
  "858632"

  iex> secret = TwoFactorInACan.Secrets.generate_totp_secret(format: :base32)
  iex> TwoFactorInACan.Totp.current_token_value(secret, secret_format: :base32)
  "743622"

  iex> secret = TwoFactorInACan.Secrets.generate_totp_secret(format: :base64)
  iex> TwoFactorInACan.Totp.current_token_value(secret, secret_format: :base64)
  "384012"
  """
  def current_token_value(secret, opts \\ []) do
    # TODO: Ensure different secret sizes work
    # TODO: Allow different token sizes
    base32_secret = convert_to_base32(secret, opts)
    :pot.totp(base32_secret)
  end

  defp convert_to_base32(secret, opts) do
    secret_format = Keyword.get(opts, :secret_format, :binary)

    case secret_format do
      :binary ->
        Base.encode32(secret)

      :base32 ->
        secret

      :base64 ->
        secret
        |> :base64.decode()
        |> Base.encode32()

      _ ->
        raise ArgumentError, """
        Invalid secret format supplied when decoding secret: 
        secret_format: #{secret_format}

        Valid options include:
        - :binary
        - :base32
        - :base64
        """
    end
  end
end