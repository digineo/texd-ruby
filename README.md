# texd

[![Gem Version](https://badge.fury.io/rb/texd.svg)](https://badge.fury.io/rb/texd)
[![Build Status](https://github.com/digineo/texd-ruby/actions/workflows/main.yml/badge.svg)](https://github.com/digineo/texd-ruby/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

texd is a Ruby client for the [texd web service](https://github.com/digineo/texd).

It leverages ActionView's template rendering mechanism to compile `.tex`
templates to PDF documents. The primary use case is to render documents
in background jobs.

## Installation

The following Rails and Ruby versions[^1] are supported
[and tested](https://github.com/digineo/texd-ruby/actions/workflows/main.yml?query=branch%3Amaster);
older versions of Ruby and Rails *may* work, but this is not guaranteed.

| ↓ Rails / Ruby → | 3.2 | 3.3 | 3.4 | 4.0 | Notes   |
|-----------------:|:----|:----|:----|:----|:--------|
| 7.0              | ✅  | ❌  | ❌  | ❌  | (1) |
| 7.1              | ✅  | ❌  | ❌  | ❌  | (1) |
| 7.2              | ✅  | ✅  | ✅  | ✅  |     |
| 8.0              | ✅  | ✅  | ✅  | ✅  | (2) |
| 8.1              | ✅  | ✅  | ✅  | ✅  | (2) |
| main branch      | ✅  | ✅  | ✅  | ✅  | (2) |

<details open><summary>Notes</summary>

1. Rails upto 7.2 depends on a version of Nokogiri which isn't available for Ruby 3.2+
2. Rails 8.0+ requires Ruby 3.2+[^2]

</details>

Install the gem and add to the application's Gemfile by executing:

    $ bundle add texd

[^1]: We're focussing on the minimal Ruby version available in [Debian Stable](https://packages.debian.org/trixie/ruby) and [Ubuntu LTS](https://packages.ubuntu.com/noble/ruby), i.e. 3.3 and 3.2 respectively. Regarding Rails, we'll cover a wider range.

[^2]: See [commit `c7b9bb1`][https://github.com/rails/rails/commit/c7b9bb1b73628daf9c9ebd56c63ce3008b31ac6f] in the Rails repository

## Configuration

Before you can use texd, you need to tell it where your instance is located.

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
  config.endpoint       = ENV.fetch("TEXD_ENDPOINT", "http://localhost:2201/")
  config.open_timeout   = ENV.fetch("TEXD_OPEN_TIMEOUT", 60)
  config.read_timeout   = ENV.fetch("TEXD_READ_TIMEOUT", 180)
  config.write_timeout  = ENV.fetch("TEXD_WRITE_TIMEOUT", 60)
  config.error_format   = ENV.fetch("TEXD_ERRORS", "full")
  config.error_handler  = ENV.fetch("TEXD_ERROR_HANDLER", "raise")
  config.tex_engine     = ENV["TEXD_ENGINE"]
  config.tex_image      = ENV["TEXD_IMAGE"]
  config.helpers        = []
  config.lookup_paths   = []
  config.lookup_paths   = [] # Rails.root.join("app/tex") is always prepended
  config.ref_cache_size = 128
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

First, create a few files:

<details><summary><code>app/views/layouts/application.tex.erb</code></summary>

This is the default layout. Here, you should define a `\documentclass`
and use `yield`. In this example, we're using ERB (Erubi) to include
dynamic content into a `.tex` file.

```erb
\documentclass{article}
\usepackage{graphicx}
<%= content_for :preamble %>

\begin{document}
<%= yield %>
\end{document}
```

</details>
<details><summary><code>app/views/document/doc.tex.erb</code></summary>

In `document/doc.tex`, we're specifying some stuff for the preamble,
render a partial, and add content for the document:

```erb
<% content_for :preamble do %>
\usepackage{blindtext}

\title{Demo document}
\date{\today}
\author{<%= user.full_name %>}
<% end %>

<%= render partial: "document/title_page" %>

\Blinddocument
```

OK, that wasn't true. We're leveraging the `blindtext` package to add
content for us :)

The `user` variable is passed as local method to `Texd.render` (see below).

</details>
<details><summary><code>app/views/document/_title_page.tex.erb</code></summary>

This partial embeds an image and creates the title page.

```erb
\begin{center}
  \includegraphics[width=0.5\linewidth]{<%= texd_attach "logo.png" %>}
\end{center}

\titlepage
```

With `texd_attach`, we're referencing a file *outside* ActionView's lookup
paths, but in Texd's lookup paths (`RAILS_ROOT/app/tex` by default).

You can use this directory to store and deploy static assets.

Please be aware, that attachments will be renamed (`att00123.png`)
in the POST body, and `att00123.png` will be returned from `texd_attach`.
You can skip the renaming, if you want/need to:

```erb
% attaches RAILS_ROOT/app/tex/logo.png, and inserts "logo.png":
<%= texd_attach "logo.png", rename: false %>

% attaches RAILS_ROOT/app/tex/logo.png, and inserts "assets/logo.png":
<%= texd_attach "logo.png", rename: "assets/logo.png" %>

% attaches RAILS_ROOT/app/tex/common.tex, and inserts "att00042" (or similar):
<%= texd_attach "common.tex", without_extension: true %>
```

</details>
<details><summary><code>app/tex/logo.png</code></summary>

*(Imagine your logo here.)*

</details>

With those files in place, you can create a PDF document:

```rb
begin
  blob = Texd.render(template: "documents/doc", locals: {
    user: User.find(1)
  })
  Rails.root.join("tmp/doc.pdf").open("wb") { |f|
    f.write blob
  }
rescue Texd::Client::QueueError => err
  # texd server is busy, please retry in a moment
rescue Texd::Client::InputError => err
  # file input processing failed, maybe some file names were invalid
rescue Texd::Client::CompilationError => err
  # compilation failed
  if err.logs
    # TeX compiler logs, only available if Texd.config.error_format
    # is "full" or "condensed"
  end
end
```

All errors inherit from `Texd::Client::RenderError` and should have
a `details` attribute (a Hash) containing the actual error returned
from the server.

## Global error reporting

texd can be configured with external error reporting, like Sentry.

This example sends the LaTeX compilation log and compiled main input `.tex`
file to Sentry:

```ruby
Texd.configure do |config|
  config.error_handler = ->(err, doc) {
    Sentry.set_context "texd", {
      details: err.details, # if config.error_format == "json"
      logs:    err.logs,    # otherwise
    }.compact
    Sentry.capture_exception(err)

    raise err # re-raise, so that your code can decide further actions
  }
end
```

`config.error_handler` must respond to `call`, and receives the error (an instance
of `Texd::Client::CompilationError`) and the document context (an instance of
`Texd::Document::Compilation`).

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
calling `make texd-docker` (which pulls and runs the `ghcr.io/digineo/texd` Docker
image). If you need to develop/test against the bleeding edge, you can clone and
run texd from source:

```console
$ cd ~/code/github.com/digineo
$ git clone git@github.com:digineo/texd
$ cd texd
$ mkdir -p tmp/refs
$ make run-container EXTRA_RUN_ARGS='--reference-store dir://./tmp/refs'
```

Note: In order to run the tests against the latest `rails/main` commit, you
need to have Ruby 3.2 or newer installed. To run the tests against all released
Rails versions, Ruby 3.2 currently suffices.

I'd recommend running `USE_DOCKER=1 make test-all` to run against all minimally
supported Ruby versions in Docker containers. This obviously requires Docker to
be installed.

Note: `USE_DOCKER=1 make test-x` *also* requires to define the endpoint for the
gem. The easiest way is to declare `TEXD_ENDPOINT=http://$CONTAINER_IP:2201/` in
addition to `USE_DOCKER=1` (substitute `$CONTAINER_IP` with the *Docker host* IP
address of the container, usually in 172.17.0.1/16).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/digineo/texd.

## License

This gem is open source under the terms of the [MIT license](./LICENSE). It is
based heavily on the [`rails-latex` gem](https://github.com/amagical-net/rails-latex).

- © 2022, Dominik Menke
- © 2010-2015, Geoff Jacobsen, Jan Baier and contributors
