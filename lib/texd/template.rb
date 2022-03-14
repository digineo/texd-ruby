# frozen_string_literal: true

require "action_view"

module Texd
  class Template < ActionView::Template::Handlers::ERB
    def call(template)
      ::Texd::Erubi.new(
        erb_source(template),
        trim:   (self.class.erb_trim_mode == "-"),
        escape: false, # disable HTML escaping
      ).src
    end

    private

    def erb_source(template)
      # First, convert to BINARY, so in case the encoding is wrong, we can still
      # find an encoding tag (<%# encoding %>) inside the String using a regular
      # expression
      tpl_src  = template.source.dup.force_encoding(Encoding::ASCII_8BIT)
      erb      = tpl_src.gsub(ENCODING_TAG, "")
      encoding = Regexp.last_match(2)

      erb.force_encoding valid_encoding(template.source.dup, encoding)

      # Always make sure we return a String in the default_internal
      erb.tap(&:encode!)
    end
  end
end

ActionView::Template.register_template_handler :erbtex, ::Texd::Template
