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
  end
end
