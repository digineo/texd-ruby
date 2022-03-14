# frozen_string_literal: true

require "uri"

module Texd
  class Configuration
    class InvalidConfig < Texd::Error
      attr_reader :option, :expected

      def initialize(msg, option:, got:, expected: nil)
        @option   = option
        @expected = expected

        message  = [format("Invalid configuration option for %p, got %p", option, got)]
        message << msg if msg
        message << format("Valid options are: %p", expected) if expected

        super message.join(" ")
      end
    end

    # This is the default configuration. It is applied in the constructor.
    DEFAULT_CONFIGURATION = {
      endpoint:     ENV.fetch("TEXD_ENDPOINT", "http://localhost:2201/"),
      error_format: ENV.fetch("TEXD_ERRORS", "full"),
      tex_engine:   ENV["TEXD_ENGINE"],
      tex_image:    ENV["TEXD_IMAGE"],
    }.freeze

    # Supported endpoint protocols.
    ENDPOINT_CLASSES = [URI::HTTP, URI::HTTPS].freeze

    # Supported error formats.
    ERROR_FORMATS = %w[json full condensed].freeze

    # Supported TeX engines.
    TEX_ENGINES = %w[xelatex lualatex pdflatex].freeze

    attr_reader(*DEFAULT_CONFIGURATION.keys)

    attr_writer :tex_image

    def initialize(**options)
      DEFAULT_CONFIGURATION.each do |key, default_value|
        public_send "#{key}=", options.fetch(key, default_value)
      end
    end

    def to_h
      DEFAULT_CONFIGURATION.keys.each_with_object({}) do |key, hash|
        hash[key] = public_send(key)
      end
    end

    def endpoint=(val)
      uri = URI.parse(val)

      unless ENDPOINT_CLASSES.any? { |klass| uri.is_a? klass }
        raise InvalidConfig.new("Value must be a URL", :endpoint, got: val, expected: ENDPOINT_CLASSES)
      end

      @endpoint = uri
    end

    def error_format=(val)
      val ||= "json"
      val   = val.to_s

      unless ERROR_FORMATS.include?(val)
        raise InvalidConfig.new(nil, got: val, expected: ERROR_FORMATS)
      end

      @error_format = val
    end

    def tex_engine=(val)
      unless val.nil?
        val = val.to_s
        unless TEX_ENGINES.include?(val)
          raise InvalidConfig.new(nil, got: val, expected: TEX_ENGINES)
        end
      end

      @tex_engine = val
    end
  end
end
