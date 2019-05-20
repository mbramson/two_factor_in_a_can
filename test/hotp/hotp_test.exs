defmodule TwoFactorInACan.HotpTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias TwoFactorInACan.Hotp

  describe "generate_token/3" do
    property "returns a 6 digit numeric string" do
      check all secret <- binary(length: 20),
                count <- integer() do
        token = Hotp.generate_token(secret, count)
        assert token =~ ~r/\d{6}/
      end
    end

    property "returns a token with base32 secret" do
      check all secret <- binary(length: 20),
                count <- integer() do
        base32_secret = :base32.encode(secret)
        token = Hotp.generate_token(base32_secret, count, secret_format: :base32)
        assert token =~ ~r/\d{6}/
      end
    end

    property "raises an ArgumentError if base32 secret cannot be decoded" do
      not_base32_secret = "not_base32"
      expected_message_regex = ~r/Secret format specified as :base32, but there was an error/

      assert_raise ArgumentError, expected_message_regex, fn ->
        Hotp.generate_token(not_base32_secret, 0, secret_format: :base32)
      end
    end

    property "returns a token with base64 secret" do
      check all secret <- binary(length: 20),
                count <- integer() do
        base64_secret = :base64.encode(secret)
        token = Hotp.generate_token(base64_secret, count, secret_format: :base64)
        assert token =~ ~r/\d{6}/
      end
    end

    property "raises an ArgumentError if base64 secret cannot be decoded" do
      not_base64_secret = "not_base64"
      expected_message_regex = ~r/Secret format specified as :base64, but there was an error/

      assert_raise ArgumentError, expected_message_regex, fn ->
        Hotp.generate_token(not_base64_secret, 0, secret_format: :base64)
      end
    end

    property "returns the same token as the :pot erlang library" do
      check all secret <- binary(length: 20),
                count <- integer() do
        base32_secret = :base32.encode(secret)
        token = Hotp.generate_token(secret, count)
        pot_token = :pot.hotp(base32_secret, count)
        assert token == pot_token
      end
    end

    property "returns the same token as the :pot erlang library with varying token length" do
      check all secret <- binary(length: 20),
                count <- integer(),
                token_length <- integer(1..100) do
        base32_secret = :base32.encode(secret)
        token = Hotp.generate_token(secret, count, token_length: token_length)
        pot_token = :pot.hotp(base32_secret, count, token_length: token_length)
        assert token == pot_token
      end
    end

    property "returns a token of the specified length" do
      check all secret <- binary(length: 20),
                count <- integer(),
                token_length <- integer(1..100) do
        token = Hotp.generate_token(secret, count, token_length: token_length)
        assert String.length(token) == token_length
      end
    end
  end

  describe "same_secret/4" do
    property "returns true for token and count generated with the same secret and count" do
      check all secret <- binary(length: 20),
                count <- integer() do
        token = Hotp.generate_token(secret, count)
        assert Hotp.same_secret?(secret, token, count)
      end
    end

    property "returns true for token and count generated with the same secret, count, and token length" do
      check all secret <- binary(length: 20),
                count <- integer(),
                token_length <- integer(1..100) do
        token = Hotp.generate_token(secret, count, token_length: token_length)
        assert Hotp.same_secret?(secret, token, count, token_length: token_length)
      end
    end

    property "returns false for when tokens do not match" do
      check all secret <- binary(length: 20),
                count <- integer(),
                token_length <- integer(1..100) do
        refute Hotp.same_secret?(secret, -1, count, token_length: token_length)
      end
    end
  end
end
