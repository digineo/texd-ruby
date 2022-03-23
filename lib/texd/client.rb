# frozen_string_literal: true

require "net/http"
require "net/http/post/multipart"
require "json"

module Texd
  class Client
    # Generic error for execptions caused by the render endpoint.
    # You will likely receive a subclass of this error, but you may
    # rescue from this error, if you're not interested in the details.
    class RenderError < Error
      # additional details
      attr_reader :details

      def initialize(message, details: nil)
        @details = details
        super(message)
      end
    end

    # @!parse
    #   # Raised if the server is busy.
    #   class QueueError < RenderError; end
    QueueError = Class.new RenderError

    # @!parse
    #   # Raised when input file pocessing failed.
    #   class InputError < RenderError; end
    InputError = Class.new RenderError

    # Raised if the TeX compilation process failed.
    class CompilationError < RenderError
      # TeX compiler logs. Only available if Texd.config.error_format
      # is "full" or "condensed".
      attr_reader :logs

      def initialize(message, details: nil, logs: nil)
        @logs = logs
        super(message, details: details)
      end
    end

    # Raised when the texd server encountered one or more unknown file
    # references.
    class ReferenceError < RenderError
      # List of unknown file references
      attr_reader :references

      def initialize(message, references:)
        @references = Set.new(references)
        super(message)
      end
    end

    ERRORS_BY_CATEGORY = {
      "input"       => InputError,
      "compilation" => CompilationError,
      "queue"       => QueueError,
      "reference"   => ReferenceError,
    }.freeze

    USER_AGENT = "texd-ruby/#{VERSION} Ruby/#{RUBY_VERSION}"

    attr_reader :config

    def initialize(config)
      @config = config
    end

    def status
      http("/status") { |uri| Net::HTTP::Get.new(uri) }
    end

    def render(upload_ios, **params)
      params = config.default_render_params.merge(params)

      http("/render", params: params) { |uri|
        Net::HTTP::Post::Multipart.new uri, upload_ios
      }
    end

    private

    def http(path, params: nil)
      uri = build_request_uri(path, params)

      Net::HTTP.start uri.host, uri.port, **request_options(uri) do |http|
        req = yield(uri)
        decode_response http.request(req)
      end
    end

    def request_options(uri)
      {
        use_ssl:       uri.scheme == "https",
        open_timeout:  config.open_timeout,
        write_timeout: config.write_timeout,
        read_timeout:  config.read_timeout,
      }
    end

    def build_request_uri(path, params)
      uri       = config.endpoint.dup
      uri.path  = File.join(uri.path, path)
      uri.query = URI.encode_www_form(params) if params
      uri
    end

    def decode_response(res)
      ct   = res["Content-Type"]
      body = case ct.split(";").first
      when "application/json"
        JSON.parse(res.body)
      when "application/pdf", "text/plain"
        res.body
      else
        raise RenderError, "unexpected content type: #{ct}"
      end

      return body if res.is_a?(Net::HTTPOK)

      raise resolve_error(res.code, ct, body)
    end

    def resolve_error(status, content_type, body)
      if body.is_a?(Hash)
        category = body.delete("category")
        message  = body.delete("error")
        err      = ERRORS_BY_CATEGORY.fetch(category, RenderError)

        if category == "reference"
          return err.new(message, references: body.delete("references"))
        end

        return err.new(message, details: body)
      end

      if content_type.start_with?("text/plain")
        return CompilationError.new("compilation failed", logs: body)
      end

      RenderError.new("Server responded with status #{status} (#{content_type})", details: body)
    end
  end
end
