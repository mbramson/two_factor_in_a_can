defmodule TwoFactorInACan.SecretsTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias TwoFactorInACan.Secrets

  describe "generate_totp_secret/1" do
    property "always returns a 20 byte binary by default" do
      check all _ <- boolean() do
        assert <<_secret::binary-size(20)>> = Secrets.generate_totp_secret()
      end
    end

    property "always returns a 32 character base32 encoded string with base32 format" do
      check all _ <- boolean() do
        secret = Secrets.generate_totp_secret(format: :base32)
        assert secret =~ ~r/[A-Z2-7]{32}/
      end
    end

    property "always returns a 28 character base64 encoded string with base64 format" do
      check all _ <- boolean() do
        secret = Secrets.generate_totp_secret(format: :base64)
        assert secret =~ ~r/[A-z\d+\/]{27}=/
      end
    end

    property "returns a key of length specified by the bytes option" do
      check all secret_bytes <- integer(1..1024) do
        secret = Secrets.generate_totp_secret(format: :binary, bytes: secret_bytes)
        assert byte_size(secret) == secret_bytes
      end
    end

    test "raises an ArgumentError for invalid format" do
      assert_raise ArgumentError, fn ->
        Secrets.generate_totp_secret(format: :invalid_format)
      end
    end
  end
end
