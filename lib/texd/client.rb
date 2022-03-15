# frozen_string_literal: true

require "net/http"
require "net/http/post/multipart"
require "json"

module Texd
  class Client
    class ResponseError < Error
      attr_reader :body, :content_type

      def initialize(code, content_type, body)
        @body         = body
        @content_type = content_type

        if json?
          super format("%s error: %s", body.delete("category"), body.delete("error"))
        elsif log?
          tex_errors = body.lines.select { |l| l.start_with?("!") }.map(&:strip)
          super "Compilation failed:\n\t#{tex_errors.join('\n\t')}"
        else
          super "Server responded with status #{code} (#{content_type})"
        end
      end

      def json?
        body.is_a?(Hash)
      end

      def log?
        content_type.start_with?("text/plain")
      end
    end

    USER_AGENT = "texd-ruby/#{VERSION} Ruby/#{RUBY_VERSION}"

    attr_reader :config

    def initialize(config)
      @config = config
    end

    def status
      http("/status") { |uri| Net::HTTP::Get.new(uri) }
    end

    def render(upload_ios)
      http("/render", params: render_query_params) { |uri|
        Net::HTTP::Post::Multipart.new uri, upload_ios
      }
    end

    private

    def http(path, params: nil)
      uri = build_request_uri(path, params)

      Net::HTTP.start uri.host, uri.port, use_ssl: uri.scheme == "https" do |http|
        req = yield(uri)
        decode_response http.request(req)
      end
    end

    def build_request_uri(path, params)
      uri       = config.endpoint.dup
      uri.path  = File.join(uri.path, path)
      uri.query = URI.encode_www_form(params) if params
      uri
    end

    def render_query_params
      {}.tap { |params|
        params[:errors] = config.error_format if config.error_format
        params[:engine] = config.tex_engine   if config.tex_engine
        params[:image]  = config.tex_image    if config.tex_image
      }
    end

    def decode_response(res)
      ct   = res["Content-Type"]
      body = case ct.split(";").first
      when "application/json"
        JSON.parse(res.body)
      when "application/pdf", "text/plain"
        res.body
      else
        raise Error, "unexpected content type: #{ct}"
      end

      return body if res.is_a?(Net::HTTPOK)

      raise ResponseError.new(res.code, ct, body)
    end
  end
end
