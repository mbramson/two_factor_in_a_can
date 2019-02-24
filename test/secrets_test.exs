defmodule TwoFactorInACan.SecretsTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias TwoFactorInACan.Secrets

  describe "generate_totp_secret/1" do
    property "always returns a 20 byte binary by default" do
      check all _ <- integer() do
        assert <<_secret::binary-size(20)>> = Secrets.generate_totp_secret()
      end
    end

    property "always returns a 32 character base32 encoded string with base32 format" do
      check all _ <- integer() do
        secret = Secrets.generate_totp_secret(format: :base32)
        assert secret =~ ~r/[A-Z2-7]{32}/
      end
    end

    property "always returns a 28 character base64 encoded string with base64 format" do
      check all _ <- integer() do
        secret = Secrets.generate_totp_secret(format: :base64)
        assert secret =~ ~r/[A-z\d+\/]{27}=/
      end
    end
  end
end
