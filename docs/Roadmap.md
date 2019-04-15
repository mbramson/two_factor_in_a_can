## Roadmap

This project is still very, very, very much under construction.

That said, here's what's planned:
- [ ] HMAC based One Time Password 2FA (HOTP)
  - [x] Secret Generation
  - [x] `Hotp.generate_token/3` function
  - [ ] `Hotp.verify_token/3` function
  - [ ] Write documentation
- [x] Time-based One Time Password 2FA (TOTP)
  - [x] Secret Generation
  - [x] `Totp.current_token_value/2` function
  - [x] `Totp.same_secret?/3` function
  - [x] Write documentation
- [ ] Universal Second Factor (U2P)
- [ ] Add examples to `README.md`
- [ ] Tutorial for adding to Phoenix

### Maybe, but probably not

2FA via text to someone's phone (SMS) is better than no 2FA at all, but there
are security users to be aware of. The main one is that it is not impossible to
intercept the communication of the token when sent to the user's phone number.
Ultimately, there are no cryptographic guarantees that the device used to
authenticate is the same device that was originally used to setup 2FA.

- [ ] SMS based 2FA
  - [ ] Thoroughly warn about not using
    - [ ] But note why its still better than no 2FA at all
  - [ ] Build OTP process tree for keeping state of recently sent SMS
  - [ ] `Sms.generate_and_send_token/2` function
  - [ ] `Sms.verify_token/3` function
  - [ ] Document to pieces

