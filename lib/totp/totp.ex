defmodule TwoFactorInACan.Totp do
  @moduledoc """
  Functions for working with time based one time password (TOTP) style two
  factory authentication as defined in RFC4226
  (https://www.ietf.org/rfc/rfc4226.txt).
  """

  alias TwoFactorInACan.Hotp

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
    time_interval = time_interval(opts)
    Hotp.generate_token(secret, time_interval, opts)
  end

  def time_interval(opts \\ []) do
    interval_seconds = Keyword.get(opts, :interval_seconds, 30)
    seconds_since_epoch = Keyword.get(opts, :injected_timestamp, now())
    seconds_since_epoch / interval_seconds |> trunc
  end

  defp now do
    DateTime.utc_now() |> DateTime.to_unix(:second)
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
