## Unreleased

[Compare changes](https://github.com/digineo/texd-ruby/compare/v0.4.2...master)

**Changes**

- add support for inline files: `<%= texd_inline "contents\n", "filename.txt" %>`

## v0.4.2 - 2022-06-16

[Compare changes](https://github.com/digineo/texd-ruby/compare/v0.4.1...v0.4.2)

**Changes**

- fix deprecation warning ("constant ::UploadIO is deprecated")

## v0.4.1 - 2022-06-16

[Compare changes](https://github.com/digineo/texd-ruby/compare/v0.3.2...v0.4.1)

**Changes**

- add support for configurable error handling

## v0.3.2 - 2022-03-28

[Compare changes](https://github.com/digineo/texd-ruby/compare/v0.2.2...v0.3.2)

**Changes**

- add support for Texd reference store
- add support for Basic Auth credentials

## v0.2.2 - 2022-03-22

[Compare changes](https://github.com/digineo/texd-ruby/compare/v0.1.0...v0.2.2)

**Fixes**

- `escape` helper now handles nil values
- improve Ruby 3.x compatability

**Changes**

- state arguments for `Texd.render`/`Texd::Document.render` explicitly
  (forbid no arbitrary arguments)
- refactor template locals

## v0.1.0 - 2022-03-14

[Compare changes](https://github.com/digineo/texd-ruby/compare/4562035e...v0.1.0)

- First public release
