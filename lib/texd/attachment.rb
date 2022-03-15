# frozen_string_literal: true

module Texd
  # AttachmentList will contain file references used in tex documents.
  # This class is commonly interacted with in the `attach_file` view
  # helper:
  #
  # @example Name mangling is active by default:
  #   \input{<%= attach_file "/path/to/reference.tex" %>}
  #   % might render as:
  #   \input{att-1234.tex}
  #
  # @example Name mangling can be deactivated:
  #   \input{<%= attach_file "/path/to/reference.tex", rename: false %>}
  #   % will render as:
  #   \input{reference.tex}
  #
  # @example Some situations require to drop the file extension:
  #   \usepackage{<%= attach_file "helper.sty", rename: false, extension: false %>}
  #   % will render as:
  #   \usepackage{helper}
  class AttachmentList
    attr_reader :items

    def initialize
      @items = {}
    end

    # Adds a file with the given `path` to the list. The output file name
    # will be mangled, unless `rename` specifies a name to use. Setting
    # `rename` to false also disables renaming (the output will then
    # use the file's basename unaltered).
    #
    # @param [ActionView::LookupContext] ctx current lookup context
    # @api private
    def attach(ctx, path, rename = true)
      # path: "foo.tex" => path="foo" prefix=current partial=false formats=[:tex]
      #       "_bar.tex" => path="bar" prefix=current partial=true formats=[:tex]
      #       "sig.png" => path="sig" prefix=current partial=false formats=[:png]
      path = ctx.view_paths.find(path, "layouts", false, formats: %i[cls tex sty lco], variants: [], locale: [],
        handlers: [])

      att = Attachment.new(path.identifier, rename, items.size)

      items[att.absolute_path] ||= att
      items[att.absolute_path]
    end

    def asset(path, rename = true)
      att = Attachment.new(path, rename, items.size)

      items[att.absolute_path] ||= att
      items[att.absolute_path]
    end

    # Transforms this list to UploadIO objects suitable for Texd::Client#render.
    #
    # @api private
    def to_upload_ios
      items.values.each_with_object({}) { |att, ios|
        ios[att.name] = att.to_upload_io
      }
    end
  end

  class Attachment
    class RenameError < ::Texd::Error
      def initialize(rename)
        super "invalid renaming: expected true, false, or a string, got #{rename.class} (#{rename})"
      end
    end

    # absolute path to attachment on local file system
    attr_reader :absolute_path

    def initialize(path, rename, index)
      @absolute_path = File.expand_path(path)

      @name = case rename
      when true   then format("att%04d%s", index, File.extname(path))
      when false  then File.basename(path)
      when String then rename
      else raise RenameError, rename
      end
    end

    def name(with_extension = true)
      basename = File.basename(@name)
      return basename if with_extension

      dot = basename.rindex(".")
      return basename if dot == 0 # file starts with "."

      basename.slice(0, dot)
    end

    # @api private
    def to_upload_io
      io = UploadIO.new(File.open(absolute_path), nil, name)
      io.instance_variable_set :@original_filename, name
      io
    end
  end
end
