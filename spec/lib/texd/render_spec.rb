# frozen_string_literal: true

require "spec_helper"

RSpec.describe Texd do
  describe "#render" do
    subject(:result) { Texd.render(template: "documents/document") }

    it { is_expected.to start_with "%PDF-1." }
  end
end
