# frozen_string_literal: true

module Texd
  # @!parse
  #   # Catch-all error for all exceptions raised by Texd
  #   class Error < StandarError; end
  Error = Class.new StandardError
end

require "rails"

require_relative "texd/version"
require_relative "texd/config"
require_relative "texd/helpers"
require_relative "texd/cache"
require_relative "texd/client"
require_relative "texd/attachment"
require_relative "texd/document"
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

  # Creates a helper module containing:
  #
  # 1. the `texd_attach` and `texd_reference` helper,
  # 2. locals passed in, transformed to helper methods, and
  # 3. any other helper configured in Text.config.helpers.
  #
  # @api private
  # @param [Texd::AttachmentList] attachments
  # @param [Hash, nil] locals
  # @return [Module] a new helper module
  def helpers(attachments, locals) # rubocop:disable Metrics/AbcSize
    locals ||= {}

    Module.new do
      include Texd::Helpers

      Texd.config.helpers.each do |mod|
        include mod
      end

      define_method :texd_attach do |path, rename: true, with_extension: true|
        attachments.attach(path, rename).name(with_extension)
      end

      define_method :texd_reference do |path, rename: true, with_extension: true|
        attachments.reference(path, rename).name(with_extension)
      end

      alias_method :texd_references, :texd_reference

      locals.each do |name, value|
        define_method(name) { value }
      end
    end
  end

  # Render compiles a template, uploads the files to the texd instance,
  # and returns the PDF.
  #
  # The arguments are directly forwarded to Texd::Document (and end up in
  # ActionView::Renderer#render).
  #
  # @example Render app/views/document/document.tex.erb
  #   begin
  #     pdf = Texd.render(template: "documents/document")
  #   rescue Texd::Client::CompilationError => err
  #     # Compilation failed and we might have a log in err.logs (only
  #     # Texd.config.error_format is "full" or "condensed").
  #     # Otherwise some details might be available in err.details.
  #   rescue Texd::Client::InputError => err
  #     # something failed during input file processing. For details see
  #     # err.details
  #   rescue Texd::Client::QueueError => err
  #     # server is busy, try again later.
  #   rescue Texd::Error => err
  #     # something went wrong before we even got to sent data to the server
  #   end
  #
  # @param [String] template name of template file in ActionView's lookup
  #   context.
  # @param [Hash, nil] locals will be made available as getter methods in
  #   the template.
  # @param [String, Boolean] layout to be used. String value name template
  #   files in `app/views/layouts`, `true` (default) uses the application
  #   layout, and `false` renders without a layout.
  # @raise [Texd::Client::ResponseError] on input and queue errors. Also on
  #   compilation errors, if Texd.config.error_format is set to JSON.
  # @raise [Texd::Error] on other Texd related errors.
  # @return [String] the PDF object
  def render(template:, locals: {}, layout: true)
    doc = Document.compile(template: template, locals: locals, layout: layout)

    client.render doc.to_upload_ios,
      input: doc.main_input_name
  rescue Client::ReferenceError => err
    # retry once with resolved references
    client.render doc.to_upload_ios(missing_refs: err.references),
      input: doc.main_input_name
  rescue Client::CompilationError => err
    config.error_handler.call(err, doc)
    nil
  end
end
