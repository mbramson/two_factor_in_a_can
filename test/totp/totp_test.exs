defmodule TwoFactorInACan.TotpTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias TwoFactorInACan.Secrets
  alias TwoFactorInACan.Totp

  describe "current_token_value/2" do
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
end
