# texd

texd is a Ruby client for the [texd web service](https://github.com/digineo/texd).

It leverages ActionView's template rendering mechanism to compile `.tex`
templates to PDF documents. The primary use case is to render documents
in background jobs.

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
  config.endpoint      = ENV.fetch("TEXD_ENDPOINT", "http://localhost:2201/")
  config.open_timeout  = ENV.fetch("TEXD_OPEN_TIMEOUT", 60)
  config.read_timeout  = ENV.fetch("TEXD_READ_TIMEOUT", 180)
  config.write_timeout = ENV.fetch("TEXD_WRITE_TIMEOUT", 60)
  config.error_format  = ENV.fetch("TEXD_ERRORS", "full")
  config.tex_engine    = ENV["TEXD_ENGINE"]
  config.tex_image     = ENV["TEXD_IMAGE"]
  config.helpers       = []
  config.lookup_paths  = [] # Rails.root.join("app/tex") is always inserted as first entry
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
