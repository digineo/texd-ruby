# frozen_string_literal: true

module Texd
  # LookupContext is used to find files accross gem, engine and application
  # barriers. This allows other gems and engines to define additional paths
  # to look into, when searching for files.
  #
  # This mechanism is useful, if you want to build a Rails engine to provide
  # default files, and reuse those defaults accross multiple Rails apps.
  #
  # To add a file to the loolup path set, configure Texd:
  #
  #   # in lib/yourgem/railtie.rb
  #   module Yourgem::Railtie < Rails::Railtie
  #     initializer "configure Texd" do
  #       Texd.configure do |config|
  #         config.lookup_paths << Pathname.new(__dir__).join("../../app/tex")
  #       end
  #     end
  #   end
  #
  # Then files in your app/tex/ directory will be used, if they are not
  # found in the host application's app/tex/ directory ("app/tex" is just
  # a convention, you could add arbitrary directories).
  class LookupContext
    MissingFileError = Class.new Error

    # A list of directories, in priority order, to search files in.
    attr_reader :paths

    # @param [Array<String, Pathname>] paths is a set of paths to search
    #   files in; usually configured with `Texd.config.lookup_paths`
    def initialize(paths)
      @paths = (paths || []).map { |path| expand(path) }
    end

    # Performs file look up in the configured paths.
    #
    # @param [String, Pathname] name of file to find.
    # @return [Pathname] path to file, when found
    # @raise [MissingFileError] when file could not be found
    def find(name)
      return expand(name) if File.absolute_path?(name)

      paths.each do |path|
        candidate = path.join(name).expand_path
        return candidate if candidate.exist?
      end

      msg  = format "file %p not found\nsearch paths:\n\t", name
      msg << paths.join("\t\n")
      raise MissingFileError, msg
    end

    private

    def expand(path)
      Pathname.new(path).expand_path
    end
  end
end
