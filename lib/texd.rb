# frozen_string_literal: true

module Texd
  Error = Class.new StandardError
end

require_relative "texd/version"
require_relative "texd/config"
require_relative "texd/erubi"
require_relative "texd/template"
require_relative "texd/client"

module Texd
  class ProcessingError < Error
    attr_reader :src, :log

    def initialize(msg = "Texd processing failed", src: nil, log: nil)
      @src = src
      @log = log
      super msg
    end
  end

  def self.configure
    yield config if block_given?
    config
  end

  def self.config
    @config ||= Configuration.new
  end

  def self.client
    if (new_hash = config.hash) && new_hash != @config_hash
      @client      = Client.new(config)
      @config_hash = new_hash
    end

    @client
  end

  def helpers
    mod = Module.new do
      extend Texd::Helpers::Latex
      extend Texd::Helpers::Use
    end

    config.helpers.each do |m|
      mod.extend(m)
    end

    mod
  end
end
