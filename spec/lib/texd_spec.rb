# frozen_string_literal: true

require "rails_helper"

RSpec.describe Texd do
  describe "#render" do
    subject(:result) { Texd.render(template: "document/document") }

    it { is_expected.not_to be_nil }
  end
end
