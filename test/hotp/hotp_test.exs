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

    property "returns a token with base64 secret" do
      check all secret <- binary(length: 20),
                count <- integer() do
        base64_secret = :base64.encode(secret)
        token = Hotp.generate_token(base64_secret, count, secret_format: :base64)
        assert token =~ ~r/\d{6}/
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
  end
end
