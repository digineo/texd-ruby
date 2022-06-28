# frozen_string_literal: true

require "uri"
require "set"

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
      endpoint:       ENV.fetch("TEXD_ENDPOINT", "http://localhost:2201/"),
      open_timeout:   ENV.fetch("TEXD_OPEN_TIMEOUT", 60),
      read_timeout:   ENV.fetch("TEXD_READ_TIMEOUT", 180),
      write_timeout:  ENV.fetch("TEXD_WRITE_TIMEOUT", 60),
      error_format:   ENV.fetch("TEXD_ERRORS", "full"),
      error_handler:  ENV.fetch("TEXD_ERROR_HANDLER", "raise"),
      tex_engine:     ENV.fetch("TEXD_ENGINE", nil),
      tex_image:      ENV.fetch("TEXD_IMAGE", nil),
      helpers:        Set.new,
      lookup_paths:   [], # Rails.root.join("app/tex") is inserted in railtie.rb
      ref_cache_size: 128,
    }.freeze

    # Supported endpoint protocols.
    ENDPOINT_CLASSES = [URI::HTTP, URI::HTTPS].freeze

    # Supported error formats.
    ERROR_FORMATS = %w[json full condensed].freeze

    # Default error handlers. One might provide a custom proc, if desired.
    ERROR_HANDLERS = {
      "raise"  => proc { |err, _doc| raise err },
      "stderr" => proc { |err, _doc| err.write_to($stderr) },
      "ignore" => proc { |_err, _doc| },
    }.freeze

    # Supported TeX engines.
    TEX_ENGINES = %w[xelatex lualatex pdflatex].freeze

    # Endpoint is a URI pointing to the texd server instance.
    #
    # The default is `http://localhost:2201/` and can be overriden by the
    # `TEXD_ENDPOINT` environment variable.
    attr_reader :endpoint

    # Timeout (in seconds) for the initial connect to the endpoint.
    #
    # The default is 60 (1 min) and can be overriden by the `TEXD_OPEN_TIMEOUT`
    # environment variable.
    attr_reader :open_timeout

    # Timeout (in seconds) for reads from the endpoint. You want this value to
    # be in the same ballbark as texd's `--compile-timoeut` option.
    #
    # The default is 180 (3 min) and can be overriden by the `TEXD_OPEN_TIMEOUT`
    # environment variable.
    attr_reader :read_timeout

    # Timeout (in seconds) for writing the request to the endpoint. You want
    # this value to be in the same ballpark as texd's `--queue-timeout` option.
    #
    # The default is 60 (1 min) and can be overriden by the `TEXD_WRITE_TIMEOUT`
    # environment variable.
    attr_reader :write_timeout

    # The texd server usually reports errors in JSON format, however, when the
    # compilation fails, the TeX compiler's output ist often most useful.
    #
    # Supported values are described in ERROR_FORMATS.
    #
    # The default is "full" and can be overriden by the `TEXD_ERRORS`
    # environment variable.
    attr_reader :error_format

    # This setting defines how to handle Texd::Client::CompilationError errors.
    #
    # Supported values are:
    #
    # - "raise", which will not process the error,
    # - "stderr", which will print the error to stderr,
    # - "ignore", which will silently discard,
    # - a Proc instance, which will delegate the error handling to it.
    #
    # The setter will lookup "raise", "stderr", and "ignore" from ERROR_HANDLERS,
    # so this attribute will always be of kind Proc.
    #
    # The default value is "raise" and can be overridden by the `TEXD_ERROR_HANDLER`
    # environment variable.
    attr_reader :error_handler

    # This is the selected TeX engine. Supported values are described in
    # TEX_ENGINES.
    #
    # The default is blank (meaning the server shall default to its `--tex-engine`
    # option), and can be overriden by the `TEXD_ENGINE` environment variable.
    attr_reader :tex_engine

    # When texd runs in container mode, it may provide multiple Docker images to
    # select from. This setting selects a specific container image.
    #
    # The default value is blank (meaning texd will select an image), and can be
    # overriden byt the `TEXD_IMAGE` environment variable.
    attr_accessor :tex_image

    # List of additional helper modules to make available in the template views.
    # Texd::Helpers is always included, and you may add additional ones.
    #
    # This can't be influenced by environment variables.
    attr_accessor :helpers

    # Set of paths to perform file lookups in. The set is searched in order,
    # meaning files found in later entries won't be returned if entries with the
    # same name exist in earlier entries.
    #
    # By default, this only contains `Rails.root.join("app/tex")`, however
    # Rails engines might append additional entries.
    #
    # A Texd::LookupContext is constructed from this set.
    attr_accessor :lookup_paths

    # Cache size for file hashes computed by Texd::Attachment::Reference.
    # Cannot be changed after the first document (using the `texd_reference`
    # helper) was renderered.
    #
    # By default, the cache keeps hashes of the last 128 reference files.
    attr_accessor :ref_cache_size

    def initialize(**options)
      DEFAULT_CONFIGURATION.each do |key, default_value|
        public_send "#{key}=", options.fetch(key, default_value.dup)
      end
    end

    def to_h
      DEFAULT_CONFIGURATION.keys.index_with do |key|
        public_send(key)
      end
    end

    # @api private
    def default_render_params
      {
        errors: error_format,
        engine: tex_engine,
        image:  tex_image,
      }.compact
    end

    def endpoint=(val)
      uri = val.is_a?(URI::Generic) ? val : URI.parse(val)

      unless ENDPOINT_CLASSES.any? { |klass| uri.is_a? klass }
        raise InvalidConfig.new("Value must be a URL", :endpoint, got: val, expected: ENDPOINT_CLASSES)
      end

      @endpoint = uri
    end

    def open_timeout=(val)
      set_timeout :open, val
    end

    def read_timeout=(val)
      set_timeout :read, val
    end

    def write_timeout=(val)
      set_timeout :write, val
    end

    def error_format=(val)
      val ||= "json"
      val   = val.to_s

      unless ERROR_FORMATS.include?(val)
        raise InvalidConfig.new(nil,
          option:   :error_format,
          got:      val,
          expected: ERROR_FORMATS)
      end

      @error_format = val
    end

    def error_handler=(val)
      val ||= "raise"
      val   = ERROR_HANDLERS.fetch(val.to_s, nil) unless val.respond_to?(:call)

      if val
        @error_handler = val
        return
      end

      raise InvalidConfig.new(nil,
        option:   :error_handler,
        got:      val,
        expected: ERROR_HANDLERS.keys + ["a Proc instance"])
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

    private

    def set_timeout(name, val)
      val = case val
      when Numeric  then val
      when String   then val.to_i
      when NilClass then 0
      else
        msg = "expected Numeric, String or NilClass for #{name}_timout, got #{val}:#{val.class}"
        raise TypeError, msg
      end

      instance_variable_set "@#{name}_timeout", val
    end
  end
end
