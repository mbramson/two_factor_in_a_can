defmodule TwoFactorInACan.Hotp do
  @moduledoc """
  Functions for working with the HMAC-based One Time Password algorithm as
  defined in RFC 4226.

  For details on RFC 4226, see https://tools.ietf.org/rfc/rfc4226.txt.
  """

  use Bitwise, only_operators: true

  @doc """
  Generates a token from a shared secret and a counter which can be
  synchronized.

  This token can be used by one party to verify whether another party has the
  same secret.

  Options:
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

  ## Examples

  ```elixir
  iex> secret = TwoFactorInACan.Secrets.generate_totp_secret()
  iex> TwoFactorInACan.Hotp.generate_token(secret, 0)
  "866564"

  iex> TwoFactorInACan.Hotp.generate_token(secret, 1)
  "532769"

  iex> TwoFactorInACan.Hotp.generate_token(secret, 0, token_length: 10)
  "1807866564"
  ```
  """
  def generate_token(secret, count, opts \\ []) do
    token_length = Keyword.get(opts, :token_length, 6)

    binary_secret = secret |> convert_to_binary(opts)

    hash = :crypto.hmac(:sha, binary_secret, count |> as_8_byte_binary)

    four_bytes_from_hash = dynamically_truncate(hash)

    four_bytes_as_integer = four_bytes_from_hash 
                            |> binary_to_integer 
                            |> wrap_to(0x7FFFFFFF)

    truncation_factor = 10 |> :math.pow(token_length) |> trunc

    token_as_integer = rem(four_bytes_as_integer, truncation_factor)

    token_as_integer
    |> :erlang.integer_to_binary()
    |> String.pad_leading(token_length, "0")
  end

  defp convert_to_binary(secret, opts \\ []) do
    secret_format = Keyword.get(opts, :secret_format, :binary)
    
    case secret_format do
      :binary ->
        secret

      :base32 ->
        secret
        |> :base32.decode()

      :base64 ->
        secret
        |> :base64.decode()

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

  defp as_8_byte_binary(integer) when is_integer(integer) do
    <<integer::size(8)-big-unsigned-integer-unit(8)>>
  end

  defp dynamically_truncate(binary) when is_binary(binary) do
    # Convert final byte of binary to a number between 0 and 15.
    # This will be uniformly randomly between 0 and 15.
    offset = :binary.at(binary, 19) &&& 15
    
    # Use that offset to randomly select 4 contiguous bytes from the original
    # binary.
    :binary.part(binary, offset, 4)
  end

  defp binary_to_integer(<<_, _, _, _>> = binary) do
    <<integer::size(4)-integer-unit(8)>> = binary
    integer
  end

  defp wrap_to(integer, wrap) when is_integer(integer) and is_integer(wrap) do
    integer &&& wrap
  end
end
