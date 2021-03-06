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
    # @return [Attachment::File]
    # @api private
    def attach(path, rename = true) # rubocop:disable Style/OptionalBooleanParameter
      add(Attachment::File, path, rename)
    end

    # Includes a file with the given `content` to the list. This is useful
    # if you generate the content on-the-fly (like creating CSV data from
    # database records), and don't want to save that content to disk first.
    #
    # In short, these examples should be mostly equivalent:
    #
    #     # use a temporary file to write contents to, and attach that file:
    #     tmp = Tempfile.new ["foo", ".csv"]
    #     tmp.write @record.to_csv
    #     tmp.flush
    #     tmp.close
    #     text_attach tmp.name
    #
    #     # skip writing to disk and inline the file:
    #     texd_inline @record.to_csv, "foo.csv"
    #
    # @param [<Type>] contents <description>
    # @param [<Type>] path <description>
    #
    # @return [<Type>] <description>
    def inline(contents, path)
      att = Attachment::Dynamic.new(path, contents)

      items[att.name] ||= att
      items[att.name]
    end

    # Adds a file reference with the given path to the list. Similar to #attach,
    # the file path must either be an absolute filename or be relative to
    # app/tex/ of the host application.
    #
    # File name mangling applies as well, with the same rules as in #attach.
    #
    # File references allow to reduce the amount of data sent to the texd server
    # instance, by initially only sending the file's checksums. If the server
    # can identify that checksum from an internal store, it'll use the stored
    # file. Otherwise we receive a list of unknown references, and can retry
    # the render request with the missing content attached in full.
    #
    # References will be stored on the server (for some amount of time), so
    # you should only attach static files, which change seldomly. Do not add
    # dynamic content.
    #
    # @param [String, Pathname] path partial path
    # @param [Boolean, String] rename affects the output file name. If
    #   `true`, a random file name is generated for the TeX template,
    #   `false` will use the basename of path.
    #   When a string is given, that string is used instead. Be careful
    #   to avoid name collisions.
    # @return [Attachment::Reference]
    # @api private
    def reference(path, rename = false) # rubocop:disable Style/OptionalBooleanParameter
      add(Attachment::Reference, path, rename)
    end

    # Adds main input file for the render request. The returned name for
    # this file is either "input.tex", or (if that name already exist)
    # some alternative. You should add the return value as input parameter
    # to the client's render call.
    #
    # @param [String] contents of main input.
    # @return [String] a generated name, usually "input.tex"
    # @api private
    def main_input(contents)
      name = "input.tex"
      i    = 0
      name = format("doc%05d.tex", i += 1) while items.key?(name)
      att  = Attachment::Dynamic.new(name, contents)

      items[name] = att
      items[name]
    end

    # Transforms this list to UploadIO objects suitable for Texd::Client#render.
    #
    # @param [Set|nil] unknown_reference_ids file references to be included fully.
    # @api private
    def to_upload_ios(unknown_reference_ids = nil)
      items.values.each_with_object({}) { |att, ios|
        ios[att.name] = if unknown_reference_ids && att.is_a?(Attachment::Reference)
          att.to_upload_io(full: unknown_reference_ids.include?(att.checksum))
        else
          att.to_upload_io
        end
      }
    end

    private

    def add(kind, path, rename)
      att = kind.new(lookup_context.find(path), rename, items.size)

      items[att.name] ||= att
      items[att.name]
    end
  end

  module Attachment
    class RenameError < ::Texd::Error
      def initialize(rename)
        super "invalid renaming: expected true, false, or a string, got #{rename.class} (#{rename})"
      end
    end

    # Computes the file name of a given path, and returns it with or without
    # file extension.
    #
    # @param [String, Pathname] path A Pathname instance or just a plain file name.
    # @param [Boolean] with_extension If true, returns the file path's basename
    #   unmodified, otherwise the file extension, including its ".", is removed.
    # @return [String] File path with or without extension.
    def self.name(path, with_extension = true) # rubocop:disable Style/OptionalBooleanParameter
      basename = ::File.basename(path)
      return basename if with_extension

      dot = basename.rindex(".")
      return basename if dot == 0 # file starts with "."

      basename.slice(0, dot)
    end

    Dynamic = Struct.new(:name, :contents) do
      def to_upload_io(**)
        Multipart::Post::UploadIO.new(StringIO.new(contents), nil, name).tap { |io|
          io.instance_variable_set :@original_filename, name
        }
      end

      def name(with_extension = true) # rubocop:disable Style/OptionalBooleanParameter
        Attachment.name(self[:name], with_extension)
      end
    end

    class Base
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
        Attachment.name(@name, with_extension)
      end
    end

    class File < Base
      # @api private
      def to_upload_io(**)
        Multipart::Post::UploadIO.new(absolute_path.open("rb"), nil, name).tap { |io|
          io.instance_variable_set :@original_filename, name
        }
      end
    end

    class Reference < Base
      # Special Content-Type header to instruct texd server to interpret
      # contents as reference identifier and re-use persisted file on server.
      USE_REF = "application/x.texd; ref=use"

      # Special Content-Type header to instruct texd server to store the
      # content body for later reference.
      STORE_REF = "application/x.texd; ref=store"

      # @api private
      def to_upload_io(full: false)
        f  = full ? absolute_path.open("rb") : StringIO.new(checksum)
        ct = full ? STORE_REF                : USE_REF

        Multipart::Post::UploadIO.new(f, ct, name).tap { |io|
          io.instance_variable_set :@original_filename, name
        }
      end

      def self.cache
        @cache ||= Cache.new(Texd.config.ref_cache_size)
      end

      # @api private
      def checksum
        @checksum ||= create_checksum
      end

      # @api private
      def create_checksum
        key = [::File.stat(absolute_path).mtime, absolute_path]
        self.class.cache.fetch(key) do
          digest  = Digest::SHA256.file(absolute_path).digest
          encoded = Base64.urlsafe_encode64(digest)
          "sha256:#{encoded}"
        end
      end
    end
  end
end
