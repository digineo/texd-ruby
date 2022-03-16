# frozen_string_literal: true

module Texd
  class Railtie < ::Rails::Railtie
    initializer "initialize texd" do
      # register MIME type for .tex files
      Mime::Type.register "text/x-tex", :tex, ["text/plain"], ["tex"]

      # prepend app/tex for Rails host application
      Texd.config.lookup_paths.unshift Rails.root.join("app/tex")
    end
  end
end
