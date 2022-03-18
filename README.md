# texd

texd is a Ruby client for the [texd web service](https://github.com/digineo/texd).

## Installation

You need to meet the following requirements for this gem to work:

- Ruby 2.7 or later
- Rails 6.0 or later

Older versions of Ruby and Rails *may* work, but this is not guaranteed.

Install the gem and add to the application's Gemfile by executing:

    $ bundle add texd

## Configuration

Befor you can use texd, you need to tell it where your instance is located.

By default, this gem reads the `TEXD_ENDPOINT` environment variable and falls
back to `http://localhost:2201/render`, should it be empty.

If this does not match your environment, you need can reconfigure texd:

```rb
Texd.configure do |config|
  config.endpoint = ENV.fetch("TEXD_ENDPOINT", "http://localhost:2201/")
end
```

<details><summary>Full default config (click to open)</summary>

```rb
Texd.configure do |config|
  config.endpoint     = ENV.fetch("TEXD_ENDPOINT", "http://localhost:2201/")
  config.error_format = ENV.fetch("TEXD_ERRORS", "full")
  config.tex_engine   = ENV["TEXD_ENGINE"]
  config.tex_image    = ENV["TEXD_IMAGE"]
  config.helpers      = []
end
```

</details>

For development environments, you can start the texd server like so (requires
Docker and about 4GB of disk space for the included TeX live installation):

```console
$ docker run --rm -d -p localhost:2201:2201 --name texd-dev digineogmbh/texd
```

Head to [the texd project page](https://github.com/digineo/texd#readme) to learn
about other installation methods.

## Usage

> TODO. See https://github.com/amagical-net/rails-latex#label-Synopsis
> in the meantime.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `lib/texd/version.rb`, and
then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and the created tag, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

You may want to run a texd server instance locally. This is easiest done by
calling either `make texd-server` (this requires Docker). If you need to
develop/test against the bleeding edge, you can clone and run texd from source:

```console
$ cd ~/code/github.com/digineo
$ git clone git@github.com:digineo/texd
$ cd texd
$ mkdir -p tmp/refs
$ make run-container EXTRA_RUN_ARGS='--reference-store dir://./tmp/refs'
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/digineo/texd.

## License

This gem is open source under the terms of the [MIT license](./LICENSE). It is
based heavily on the [`rails-latex` gem](https://github.com/amagical-net/rails-latex).

- © 2022, Dominik Menke
- © 2010-2015, Geoff Jacobsen, Jan Baier and contributors
