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

  This function can also accept all of the options accepted by
  `TwoFactorInACan.Totp.time_interval/1`. It simply passes them through when
  retrieving the time interval to pass in as the count to the
  `TwoFactorInACan.Hotp.generate_token/3` function.

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

  @doc """
  Calculates the current time interval as an integer used in the HOTP algorithm
  to calculate the current token value.

  The following options are supported:
  - `:offset_seconds` (Default: 0) - The number of seconds to offset the
    current timestamp by. If the current timestamp was 600 and the offset was
    60, then the timestamp of 660 would be used to calculate the time interval.
    This can be useful to account for drift or to purposefully allow the last
    token to be valid as well in functions that use this function.
  - `:interval_seconds` (Default: 30) - The number of seconds that must pass
    before a new time_interval (and thus TOTP token) is returned by this
    function. This should probably never be anything but the default (30
    seconds) during actual use, as nearly all apps that generate TOTP tokens
    assume a 30 second interval.
  - `:injected_timestamp` (default: current time) - The unix timestamp to use
    when calculating the time interval. This should only be used during testing
    to ensure the same token or interval is always returned. When this option
    is not supplied, the current timestamp is used.

  # Examples

  iex> TwoFactorInACan.Totp.time_interval()
  51802243

  iex> TwoFactorInACan.Totp.time_interval(offset_seconds: 30)
  51802244

  iex> TwoFactorInACan.Totp.time_interval(interval_seconds: 60)
  25901122

  iex> TwoFactorInACan.Totp.time_interval(injected_timestamp: 1554067403)
  51802246

  iex> TwoFactorInACan.Totp.time_interval(injected_timestamp: 60, interval_seconds: 10)
  6
  """
  @spec time_interval([key: :atom]) :: integer()
  def time_interval(opts \\ []) do
    offset = Keyword.get(opts, :offset_seconds, 0)
    interval_seconds = Keyword.get(opts, :interval_seconds, 30)
    seconds_since_epoch = Keyword.get(opts, :injected_timestamp, now()) + offset
    seconds_since_epoch / interval_seconds |> trunc
  end

  def same_secret?(secret, token, opts \\ []) do
    acceptable_future_tokens = Keyword.get(opts, :acceptable_future_tokens, 0)
    acceptable_past_tokens = Keyword.get(opts, :acceptable_past_tokens, 0)
    interval_seconds = Keyword.get(opts, :interval_seconds, 30)
    {offset_seconds, opts} = Keyword.pop(opts, :offset_seconds, 0)

    time_intervals_to_check = -acceptable_past_tokens..acceptable_future_tokens

    Enum.any?(time_intervals_to_check, fn offset ->
      this_interval_offset_seconds = offset * interval_seconds + offset_seconds
      opts_with_offset =
        Keyword.put(opts, :offset_seconds, this_interval_offset_seconds)

      token == current_token_value(secret, opts_with_offset)
    end)
  end

  defp now do
    DateTime.utc_now() |> DateTime.to_unix(:second)
  end
end
