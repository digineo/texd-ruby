# frozen_string_literal: true

require "spec_helper"

RSpec.describe Texd::Configuration do
  subject(:config) { Texd::Configuration.new(**user_config) }

  let(:user_config) { {} }

  describe "defaults" do
    it { expect(config.endpoint).to      eq    URI(Texd::Configuration::DEFAULT_CONFIGURATION[:endpoint]) }
    it { expect(config.error_format).to  eq    Texd::Configuration::DEFAULT_CONFIGURATION[:error_format] }
    it { expect(config.error_handler).to be    Texd::Configuration::ERROR_HANDLERS.fetch("raise") }
    it { expect(config.tex_engine).to    eq    Texd::Configuration::DEFAULT_CONFIGURATION[:tex_engine] }
    it { expect(config.tex_image).to     eq    Texd::Configuration::DEFAULT_CONFIGURATION[:tex_image] }
    it { expect(config.helpers).to       match Texd::Configuration::DEFAULT_CONFIGURATION[:helpers] }
    it { expect(config.lookup_paths).to  match Texd::Configuration::DEFAULT_CONFIGURATION[:lookup_paths] }
  end

  describe "with user options" do
    let(:user_config) {
      {
        endpoint:      "https://texd.example.com:2345",
        lookup_paths:  [__dir__],
        error_handler: proc { "hi!" },
      }
    }

    it { expect(config.endpoint).to      eq    URI(user_config[:endpoint]) }
    it { expect(config.error_format).to  eq    Texd::Configuration::DEFAULT_CONFIGURATION[:error_format] }
    it { expect(config.error_handler).to be    user_config[:error_handler] }
    it { expect(config.tex_engine).to    eq    Texd::Configuration::DEFAULT_CONFIGURATION[:tex_engine] }
    it { expect(config.tex_image).to     eq    Texd::Configuration::DEFAULT_CONFIGURATION[:tex_image] }
    it { expect(config.helpers).to       match Texd::Configuration::DEFAULT_CONFIGURATION[:helpers] }
    it { expect(config.lookup_paths).to  match user_config[:lookup_paths] }
  end

  it "modifiying settings doesn't affect defaults" do
    expect {
      config.lookup_paths << __dir__
    }.not_to(change { Texd::Configuration::DEFAULT_CONFIGURATION[:lookup_paths] })
  end
end
