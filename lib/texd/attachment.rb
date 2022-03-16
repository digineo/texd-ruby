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
    attr_reader :lookup_context

    # @param [Texd::LookupContext] lookup_context
    def initialize(lookup_context)
      @items          = {}
      @lookup_context = lookup_context
    end

    # Adds a file with the given `path` to the list. The file path must
    # either be an absolute filename or be relative to app/tex/ of the
    # host application. See `Texd::LookupContext` for details.
    #
    # The output file name will be mangled, unless `rename` specifies a
    # name to use. Setting `rename` to false also disables renaming (the
    # output will then use the file's basename unaltered).
    #
    # Note: Adding the same `path` twice with different arguments will
    # have no effect: The returned value on the second attempt will be the
    # same as on the first one.
    #
    # @param [String, Pathname] path partial path
    # @param [Boolean, String] rename affects the output file name. If
    #   `true`, a random file name is generated for the TeX template,
    #   `false` will use the basename of path.
    #   When a string is given, that string is used instead. Be careful
    #   to avoid name collisions.
    # @return [Attachment]
    # @api private
    def attach(path, rename = true) # rubocop:disable Style/OptionalBooleanParameter
      att = Attachment.new(lookup_context.find(path), rename, items.size)

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

    # @param [Pathname] path see AttachmentList#attach
    # @param [Boolean, String] rename see AttachmentList#attach
    # @param [Integer] serial number of files currently in the parent
    #   AttachmentList (used for renaming purposes)
    # @api private
    def initialize(path, rename, serial)
      @absolute_path = path.expand_path

      @name = case rename
      when true   then format("att%04d%s", serial, path.extname)
      when false  then path.basename.to_s
      when String then rename
      else raise RenameError, rename
      end
    end

    # Returns the (renamed) output file name. When `with_extension` is
    # `true`, the file extension is chopped.
    #
    # @param [Boolean] with_extension
    # @return [String] output file name
    def name(with_extension = true) # rubocop:disable Style/OptionalBooleanParameter
      basename = File.basename(@name)
      return basename if with_extension

      dot = basename.rindex(".")
      return basename if dot == 0 # file starts with "."

      basename.slice(0, dot)
    end

    # @api private
    def to_upload_io
      io = UploadIO.new(absolute_path.open("r"), nil, name)
      io.instance_variable_set :@original_filename, name
      io
    end
  end
end
