defmodule TwoFactorInACan.TotpTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias TwoFactorInACan.Secrets
  alias TwoFactorInACan.Totp

  describe "current_token_value/2" do
    property "returns the same result as the pot erlang library" do
      check all secret <- binary(length: 20) do
        returned_token = Totp.current_token_value(secret, secret_format: :binary)
        base32_secret = :base32.encode(secret)
        pot_token = :pot.totp(base32_secret)

        # Retry it once since the timestamp can drift resulting in a different
        # time_interval fed to hotp for each calculation. Retrying should
        # happen extremely quick and result in the time_intervals both being
        # calculated in an interval which cannot result in them differing.
        if returned_token != pot_token do
          retried_token = Totp.current_token_value(secret, secret_format: :binary)
          retried_pot_token = :pot.totp(base32_secret)
          assert retried_token == retried_pot_token
        end
      end
    end

    property "returns the same result as the pot erlang library for specified time intervals" do
      check all secret <- binary(length: 20),
        interval_seconds <- positive_integer(),
        injected_timestamp <- integer()
      do
        opts = [
          interval_seconds: interval_seconds,
          injected_timestamp: injected_timestamp,
          secret_format: :binary
        ]

        megaseconds = div(injected_timestamp, 1_000_000)
        seconds = rem(injected_timestamp, 1_000_000)
        pot_timestamp = {megaseconds, seconds, 99}
        pot_opts = [interval_length: interval_seconds, timestamp: pot_timestamp]
        base32_secret = :base32.encode(secret)

        returned_token = Totp.current_token_value(secret, opts)
        pot_token = :pot.totp(base32_secret, pot_opts)
        assert returned_token == pot_token
      end
    end

    property "returns a 6 digit numeric string with binary key" do
      check all _ <- boolean() do
        secret = Secrets.generate_totp_secret(format: :binary)
        token = Totp.current_token_value(secret, secret_format: :binary)
        assert token =~ ~r/\A\d{6}\z/
      end
    end

    property "returns a 6 digit numeric string with base32 key" do
      check all _ <- boolean() do
        secret = Secrets.generate_totp_secret(format: :base32)
        token = Totp.current_token_value(secret, secret_format: :base32)
        assert token =~ ~r/\A\d{6}\z/
      end
    end

    property "returns a 6 digit numeric string with base64 key" do
      check all _ <- boolean() do
        secret = Secrets.generate_totp_secret(format: :base64)
        token = Totp.current_token_value(secret, secret_format: :base64)
        assert token =~ ~r/\A\d{6}\z/
      end
    end

    test "raises an ArgumentError for invalid secret_format" do
      assert_raise ArgumentError, fn ->
        secret = Secrets.generate_totp_secret()
        Totp.current_token_value(secret, secret_format: :invalid_format)
      end
    end
  end

  describe "time_interval/1" do
    property "returns a positive integer" do
      returned_interval = Totp.time_interval()
      assert is_integer(returned_interval)
      assert returned_interval > 0
    end

    property "returns a time interval offset from the current one" do
      check all offset <- integer() do
        offset_seconds = offset * 30

        current_interval = Totp.time_interval(injected_timestamp: 10_000)

        offset_interval =
          Totp.time_interval(
            injected_timestamp: 10_000,
            offset_seconds: offset_seconds
          )

        assert offset_interval == current_interval + offset
      end
    end

    property "returns a time interval offset from current one with custom interval" do
      check all offset <- integer(),
        interval <- positive_integer() do

        offset_seconds = offset * interval

        current_interval =
          Totp.time_interval(
            injected_timestamp: 10_000,
            interval_seconds: interval
        )

        offset_interval =
          Totp.time_interval(
            injected_timestamp: 10_000,
            interval_seconds: interval,
            offset_seconds: offset_seconds
          )

        assert offset_interval == current_interval + offset
      end
    end

    property "always returns the same interval as the :pot erlang library" do
      check all interval_seconds <- positive_integer(),
        injected_timestamp <- integer()
      do
        opts = [interval_seconds: interval_seconds, injected_timestamp: injected_timestamp]
        megaseconds = div(injected_timestamp, 1_000_000)
        seconds = rem(injected_timestamp, 1_000_000)
        pot_timestamp = {megaseconds, seconds, 99}
        pot_opts = [interval_length: interval_seconds, timestamp: pot_timestamp]

        assert Totp.time_interval(opts) == :pot.time_interval(pot_opts)
      end
    end
  end

  describe "same_secret?/3" do
    # Note: This test will be flaky if current token value changes in the tiny
    # amount of time between the two token calculations.
    property "returns true if token is generated with the same secret" do
      check all secret <- binary(length: 20) do
        token = Totp.current_token_value(secret)
        assert Totp.same_secret?(secret, token)
      end
    end

    # Note: Flaky test. This test will fail if the token for 30 seconds ago
    # happens to match the the current token. There is a 1/1_000_000 chance of
    # this happening.
    property "returns false if token is generated for 30 seconds in the past" do
      check all secret <- binary(length: 20) do
        thirty_seconds_ago =
          (DateTime.utc_now() |> DateTime.to_unix(:second)) - 30

        thirty_seconds_ago_token =
          Totp.current_token_value(secret, injected_timestamp: thirty_seconds_ago)

        refute Totp.same_secret?(secret, thirty_seconds_ago_token)
      end
    end

    property "returns true for token that is in the acceptable future token range" do
    end

    property "returns false for token that is outside the acceptable future token range" do
    end

    property "returns true for token that is in the acceptable past token range" do
    end

    property "returns false for token that is outside the acceptable past token range" do
    end

    # Test both future and past range acceptance
  end
end
