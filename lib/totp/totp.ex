defmodule TwoFactorInACan.Totp do
  @moduledoc """
  Provides functions for working with time based one time password (TOTP) style
  two factor authentication (2FA) as defined in RFC 4226.

  ## Summary

  For details on RFC 4226, see https://tools.ietf.org/rfc/rfc4226.txt.

  TOTP two factor authentication uses the HMAC-based one time password (HOTP)
  algorithm with the current time passed in as the count to verify that the end
  user and the consuming application have the same secret.

  It does this by generating a token from the current time and secret and
  comparing the generated secret to the one the end user has supplied. If they
  match, then it is extremely unlikely that the end user does not have a
  different secret.

  ## Security Concerns

  When implementing 2FA using TOTP it is very important to also lock out any
  users which do not send a matching token some small number of consecutive
  times. By default tokens are 6 characters long which means that there is a
  1/1,000,000 chance of guessing correctly. This is relatively trivial to brute
  force without some lock out mechanism.

  Care should also be token when adjusting the token length. Longer tokens are
  more secure, and shorter tokens are less secure (as they are easier to
  guess).

  If there is drift between clocks of users and the machine verifying tokens
  then the `acceptable_past_tokens` and `acceptable_future_tokens` options can
  be used to specify a window of acceptable tokens. This can also be useful to
  allow users to still submit tokens which were just seconds ago valid as a
  user experience enhancement.

  It should be noted that increasing the window of acceptable tokens also makes
  it easier to randomly guess a token. Care should be taken to way the pros and
  cons of this. As an example, by allowing one past token and one future token
  to be valid, there are now (usually) 3 tokens that an attacker could guess.
  This increases the chance of successfully guessing tokens to 1/333,333.

  ## Example Usage

  ### Secret Generation
  When a user first sets up TOTP 2FA, the server must generate a secret that
  will be shared between the server and the user. The `TwoFactorInACan.Secrets`
  module can be used for this.

  ```elixir
  secret = TwoFactorInACan.Secrets.generate_totp_secret()
  <<109, 159, 180, 42, 128, 80, 183, 56, 163, 232, 151, 242, 233, 37, 167, 178,
    253, 23, 18, 159>>
  ```

  Every user should have a different secret. No secrets should be shared.

  ### Transmitting the Secret to the User

  This secret must be securely transmitted to the user. It is extremely
  important that the method of transfer is secure. If an attacker can intercept
  the secret in transit, then they will be able to entirely bypass this form of
  2FA. The attacker then only needs to acquire the user's password and this 2FA
  method is rendered useless.

  Using HTTPS is a must for transferring this secret. Do not transfer anything
  over HTTP!

  A common method of transferring the secret to an end user is by generating a
  QR code containing the secret. Smart phone applications such as Google
  Authenticator, Duo, and Authy can then scan these codes, extract the secret,
  and securely store the secret.

  For these applications to understand that a secret is being transmitted, the
  following url should be encoded to a QR Code:

  ```elixir
  "otpauth://totp/MyDescription?secret=MySecret&issuer=MyAppName"
  |> MyQRModule.encode # Note: Not a real module!
  ```

  In the above URL, MySecret should be the secret encoded in base32, MyAppName
  and MyDescription can be anything, and assist the user in figuring out which
  token to use on your site if they have many.

  ### Verify User Received Secret

  At this point the end user should be asked to supply the current token as
  generated by their authenticator application.

  Upon receiving the token from the user, it should be verified against the
  secret generated earlier.

  ```elixir
  TwoFactorInACan.Totp.same_secret?(generated_secret, user_supplied_token)
  true
  ```

  If the above function returns `true` then the the user has properly setup
  2FA.

  If it returns `false`, then the incorrect token was sent. The user will need
  to send another correct token before their account should be configured to
  require TOTP 2FA at login.

  ### Store the secret

  The server will need to store the generated secret in some manner associated
  with the user so that it can be used to verify the user's identity at login.

  Care should be taken to ensure this is stored securely. If storing in a
  database, the database should be encrypted. Even if the database is
  encrypted, the field should be encrypted. You can even go the extra mile and
  use a different encryption key per user stored with the key stored outside of
  the database.

  If the secret is leaked or compromised by an attacker, then the attacker will
  be able to bypass this method of 2FA. In this event, the user should be
  prompted to re-setup TOTP 2FA. Ideally the user's account should be locked
  down until they can prove their identity through other means.

  ### Verify Token at Login

  When the user logs in, they should also supply the current TOTP token. The
  server should verify that the supplied TOTP token is generated using the same
  secret that is stored associated with that user.

  ```elixir
  TwoFactorInACan.Totp.same_secret?(stored_user_secret, user_supplied_token)
  true
  ```

  If this returns true, then the user has sufficiently proven their identity
  and authentication should succeed (assuming they also supplied the correct
  password!)

  If this returns false, then login should fail.

  It can be a good practice to provide the user with a message that does not
  reveal whether the username didn't exist, the password was wrong, or 2FA
  failed. This makes an attackers job more difficult. There is some debate on
  whether this is an effective security measure.
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

  The following options are supported:
  - `:secret_format` - the format that the secret is passed in as. Options
    include:
    - `:binary` (default)
    - `:base32`
    - `:base64`
  - `:token_length` (Default: 6) - the length of the generated token. A longer
    token is harder to guess and thus more secure. A longer token can also be
    more difficult for users to accurately transmit. Although everything in
    `TwoFactorInACan` supports variable token length, you should be sure that
    other apps and programs used support the token length set here.
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

  ```elixir
  iex> secret = TwoFactorInACan.Secrets.generate_totp_secret()
  iex> TwoFactorInACan.Totp.current_token_value(secret)
  "858632"

  iex> secret = TwoFactorInACan.Secrets.generate_totp_secret(format: :base32)
  iex> TwoFactorInACan.Totp.current_token_value(secret, secret_format: :base32)
  "743622"

  iex> secret = TwoFactorInACan.Secrets.generate_totp_secret(format: :base64)
  iex> TwoFactorInACan.Totp.current_token_value(secret, secret_format: :base64)
  "384012"
  ```
  """
  def current_token_value(secret, opts \\ []) do
    time_interval = time_interval(opts)
    Hotp.generate_token(secret, time_interval, opts)
  end

  @doc """
  Calculates the current time interval as an integer used in the HOTP algorithm
  as the count to calculate the current token value.

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

  ## Examples

  ```elixir
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
  ```
  """
  @spec time_interval([key: :atom]) :: integer()
  def time_interval(opts \\ []) do
    offset = Keyword.get(opts, :offset_seconds, 0)
    interval_seconds = Keyword.get(opts, :interval_seconds, 30)
    seconds_since_epoch = Keyword.get(opts, :injected_timestamp, now()) + offset
    intervals_since_epoch = seconds_since_epoch / interval_seconds
    trunc(intervals_since_epoch)
  end

  @doc """
  Verifies that the provided TOTP token was generated using the provided
  secret.

  This function uses the secret to generate a token. It then compares the
  generated token to the supplied token. If they match, then it can be
  probabilistically inferred that the entity that supplied the token also knew
  the secret.

  This function allows a number of options:
  - `:acceptable_past_tokens` (Default: `0`) - The number of past tokens which
    should result in this function returning true. Setting this to `1` can be a
    friendly way to allow users to still verify if they have taken too long to
    submit their token. It should be noted that this does result in two tokens
    being valid instead of one, which makes a valid token easeier to guess.
    This value should not be set too high or security is greatly compromised.
  - `:acceptable_future_tokens` (Default: `0`) - The number of future tokens
    which should result in this function returning true. It should be noted
    that setting this to a nonzero value will allow more tokens to be valid and
    thus make a valid token easier to guess. This value should not be set too
    high or security is greatly compromised.
  - `:token_length` (Default: 6) - the length of the generated token. A longer
    token is harder to guess and thus more secure. A longer token can also be
    more difficult for users to accurately transmit. Although everything in
    `TwoFactorInACan` supports variable token length, you should be sure that
    other apps and programs used support the token length set here.
  - `:offset_seconds` (Default: `0`) - The number of seconds to offset the
    current timestamp by. If the current timestamp was 600 and the offset was
    60, then the timestamp of 660 would be used to calculate the time interval.
    This can be useful to account for drift or difference in clock times
    between two entities.
  - `:interval_seconds` (Default: `30`) - The number of seconds that must pass
    before a new time_interval (and thus TOTP token) is returned by this
    function. This should probably never be anything but the default (30
    seconds) during actual use, as nearly all apps that generate TOTP tokens
    assume a 30 second interval.
  - `:injected_timestamp` (default: current time) - The unix timestamp to use
    when calculating the time interval. This should only be used during testing
    to ensure the same token or interval is always returned. When this option
    is not supplied, the current timestamp is used.
  - `:secret_format` (default: `:binary`) - The format of the passed in secret.
    Can be one of `:binary`, `:base32`, or `:base64`.

  ## Examples

  ```elixir
  iex> secret = TwoFactorInACan.Secrets.generate_totp_secret()
  iex> current_token = TwoFactorInACan.Totp.current_token_value(secret)
  iex> TwoFactorInACan.Totp.same_secret?(secret, current_token)
  true
  ```
  """
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
