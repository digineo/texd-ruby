## Unreleased

[Compare changes](https://github.com/digineo/texd-ruby/compare/v0.6.0...master)

## v0.7.0 - 2025-10-20

**Changes**

- Drop official support for Ruby < 3.2 and Rails < 7.0
- Add support for Rails 8.1.0.rc1
- Set `required_ruby_version` to >= 3.2.0

## v0.6.0 - 2024-02-13

**Changes**

- Add another optional argument to the `escape` helper, to disallow replacing
  of hyphens.

  Previously, `escape(str, typographic: true)` did replace the hyphen between
  word-characters with `"=` (i.e. the babel shorthand for a hard-hyphen in German
  locale).

  Now it is possible to disable the hyphenation replacement explicitly:

  ```erb
  <%= escape str, hyphenation: false %>
  ```

  The default value for the `hyphenation` option defaults to the value given to
  the `typographic` option (which in turn is true by default).


[Compare changes](https://github.com/digineo/texd-ruby/compare/v0.5.1...v0.6.0)

## v0.5.1 - 2022-10-10

**Changes**

This is a maintenance release. Expect full compatability with v0.5.0.

- update dependencies
- add specs for rails/main

[Compare changes](https://github.com/digineo/texd-ruby/compare/v0.5.0...v0.5.1)

## v0.5.0 - 2022-07-22

[Compare changes](https://github.com/digineo/texd-ruby/compare/v0.4.2...v0.5.0)

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
