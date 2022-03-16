# frozen_string_literal: true

require "spec_helper"

RSpec.describe Texd::LookupContext do
  describe "#render" do
    subject(:ctx) { Texd::LookupContext.new(paths) }

    let(:paths) { [] }

    matcher :match_context_lookup do |expected|
      match do |name|
        ctx.find(name) == file_fixture(expected)
      rescue Texd::LookupContext::MissingFileError
        false
      end
    end

    matcher :report_missing_file do
      match do |name|
        ctx.find(name)
        false
      rescue Texd::LookupContext::MissingFileError => err
        return err.message.start_with?(%(file "#{name}" not found))
      end
    end

    it { expect("nonexistent.cls").to report_missing_file }

    context "with non-empty pathset" do
      def fixture_dir(name)
        Pathname.new(RSpec.configuration.file_fixture_path).expand_path.join(name)
      end

      let(:paths) { [fixture_dir("lookup/a")] }

      it { expect("file.sty").to match_context_lookup "lookup/a/file.sty" }
      it { expect("other.lco").to report_missing_file }

      context "with multiple paths" do
        let(:paths) { [fixture_dir("lookup/a"), fixture_dir("lookup/b")] }

        it { expect("file.sty").to match_context_lookup "lookup/a/file.sty" }
        it { expect("other.lco").to match_context_lookup "lookup/b/other.lco" }
        it { expect("nonexistent").to report_missing_file }
      end
    end
  end
end
