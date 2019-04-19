# 0.1.2

- Add the `TwoFactorInACan.Hotp.same_secret?/4` function for verifying HOTP
  tokens.
- Drastically improve the documentation in the `TwoFactorInACan.Totp` module.

# 0.1.1

- Fixed issues with projects that did not also have :pot as a dependency. All
  functions which rely on `TwoFactorInACan.Hotp.generate_token/3` should now
  work in such projects.
- Added better error messages when a base32 or base64 secret is passed in which
  cannot be decoded using `Base.decode32/1` or `Base.decode64/1`, respectively.

# 0.1.0

Initial Release
