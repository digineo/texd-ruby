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
    # @param [String] template name of template file in ActionView's lookup
    #   context.
    # @param [Hash, nil] locals will be made available as getter methods in
    #   the template.
    # @return [Compilation]
    def compile(template:, locals: {})
      helper_mod = ::Texd.helpers(attachments, locals)
      tex_source = Class.new(ApplicationController) {
        helper helper_mod
      }.render(template: template, format: :tex)

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
