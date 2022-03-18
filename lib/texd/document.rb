# frozen_string_literal: true

module Texd
  # Document handles compiling of templates into TeX sources.
  class Document
    attr_reader :attachments

    # Shorthand for `new.compile`.
    def self.compile(*args)
      new.compile(*args)
    end

    def initialize
      context      = LookupContext.new(Texd.config.lookup_paths)
      @attachments = AttachmentList.new(context)
    end

    # Compile converts templates into TeX sources and collects file
    # references (created with `texd_attach` and `texd_reference` helpers).
    #
    # @param args are forwarded to ApplicationController#render (which in turn
    #   forwards to ActionView::Renderer#render).
    # @return [Compilation]
    def compile(*args)
      helper_mod = ::Texd.helpers(attachments)
      tex_source = Class.new(ApplicationController) {
        helper helper_mod
      }.render(*args)

      main = attachments.main_input(tex_source)
      Compilation.new(main.name, attachments)
    end

    Compilation = Struct.new(:main_input_name, :attachments) do
      def to_upload_ios(missing_refs: Set.new)
        attachments.to_upload_ios(missing_refs)
      end
    end
  end
end
