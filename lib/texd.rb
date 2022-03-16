# frozen_string_literal: true

module Texd
  Error = Class.new StandardError
end

require "rails"

require_relative "texd/version"
require_relative "texd/config"
require_relative "texd/helpers"
require_relative "texd/client"
require_relative "texd/attachment"
require_relative "texd/lookup_context"
require_relative "texd/railtie"

module Texd
  extend self

  # Reconfigures Texd. Should be called once in your initializer.
  #
  # @example config/initializers/texd.rb
  #   Texd.configure do |config|
  #     config.endpoint     = ENV.fetch("TEXD_ENDPOINT", "http://localhost:2201/")
  #     config.error_format = ENV.fetch("TEXD_ERRORS", "full")
  #     config.tex_engine   = ENV["TEXD_ENGINE"]
  #     config.tex_image    = ENV["TEXD_IMAGE"]
  #     config.helpers      = []
  #     config.lookup_paths = [Rails.root.join("app/tex")]
  #   end
  #
  # @yield [Texd::Configuration] the previous config object
  # @return [Texd::Configuration] the new current config object
  def configure
    yield config if block_given?
    config
  end

  # @return [Texd::Configuration] the current config object.
  def config
    @config ||= Configuration.new
  end

  # @return [Texd::Client] the currently configured HTTP client.
  def client
    if (new_hash = config.hash) && new_hash != @config_hash
      @client      = Client.new(config)
      @config_hash = new_hash
    end

    @client
  end

  # Creates a helper module containing (a) the `texd_attach` helper,
  # and (b) any other helper configured in Text.config.helpers.
  #
  # This needs to be dynamic, because the attachment list is volatile.
  #
  # @api private
  def helpers(attachments)
    Module.new do
      include Texd::Helpers

      define_method :texd_attach do |path, rename: true, with_extension: true|
        attachments.attach(path, rename).name(with_extension)
      end

      Texd.config.helpers.each do |mod|
        include mod
      end
    end
  end

  # Render compiles a template, uploads the files to the texd instance,
  # and returns the PDF.
  #
  # Other arguments are directly forwarded to ApplicationController#render
  # (which in turn delegates to ActionView::Renderer#render).
  #
  # @example Render app/views/document/document.tex.erb
  #   begin
  #     pdf = Texd.render(template: "documents/document")
  #   rescue Texd::Client::ResponseError => err
  #     if err.json?
  #       # likely an input error, like missing files or invalid file names.
  #       # inspect err.body for details
  #     elsif err.log?
  #       # compilation error. only available when Texd.config.error_format
  #       # is either "full" or "condensed"
  #     else
  #       # something else went wrong
  #     end
  #   rescue Texd::Error => err
  #     # something went wrong before we even got to sent data to the server
  #   end
  #
  # @raise [Texd::Client::ResponseError] on input and queue errors. Also on
  #   compilation errors, if Texd.config.error_format is set to JSON.
  # @raise [Texd::Error] on other Texd related errors.
  # @return [String] the PDF object
  def render(*args)
    context     = LookupContext.new(config.lookup_paths)
    attachments = AttachmentList.new(context)

    renderer = Class.new(ApplicationController) {
      helper ::Texd.helpers(attachments)
    }.renderer

    tex_source       = renderer.render(*args)
    ios              = attachments.to_upload_ios
    input_io         = UploadIO.new(StringIO.new(tex_source), nil, "input.tex")
    input_io.instance_variable_set :@original_filename, "input.tex"
    ios["input.tex"] = input_io

    client.render(ios)
  end
end
