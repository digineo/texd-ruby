# frozen_string_literal: true

require "spec_helper"

RSpec.describe Texd do
  describe "#render" do
    subject(:result) { Texd.render(template: template, locals: locals) }

    let(:locals)   { nil }
    let(:template) { "documents/document" }

    it { is_expected.to start_with "%PDF-1." }

    def reconfigure!(**knobs)
      config = Texd.config.to_h.merge(knobs)
      allow(Texd).to receive(:config).and_return(Texd::Configuration.new(**config))
    end

    context "broken input" do
      let(:template) { "broken/missing" }

      def expect_compilation_error
        subject
        expect(nil).to be_a Texd::Client::CompilationError
      rescue Texd::Client::CompilationError => err
        yield err
      rescue StandardError => err
        expect(err).to be_a Texd::Client::CompilationError
      end

      it "raises an error" do
        expect { subject }.to raise_error Texd::Client::CompilationError
      end

      it "may contain the full log" do
        reconfigure!(error_format: "full")

        expect_compilation_error do |err|
          expect(err.details).to be_blank
          expect(err.logs).to match(/This is XeTeX, Version 3./)
          expect(err.logs).to match(/! LaTeX Error: File `missing\.tex' not found/)
        end
      end

      it "may contain a condensed log" do
        reconfigure!(error_format: "condensed")

        expect_compilation_error do |err|
          expect(err.details).to be_blank
          expect(err.logs).not_to match(/This is XeTeX, Version 3./)
          expect(err.logs).not_to match(/! LaTeX Error: File `missing\.tex' not found/)
          expect(err.logs).to     match(/LaTeX Error: File `missing\.tex' not found/)
        end
      end

      it "may contain a JSON log" do
        reconfigure!(error_format: "json")

        expect_compilation_error do |err|
          expect(err.logs).to be_blank
          expect(err.details).to match a_hash_including(
            "cmd"    => "latexmk",
            "output" => a_string_matching(/Log file says no output from latex/),
          )
        end
      end
    end

    context "with custom helper" do
      let(:template) { "my_helper/doc" }

      it "can call helper methods" do
        reconfigure! helpers: Set[Module.new {
          def my_helper_method
            42
          end
        }]
        is_expected.to start_with "%PDF-1."
      end
    end

    context "with locals" do
      let(:locals)   { { my_helper_method: "21\\times 2" } }
      let(:template) { "my_helper/doc" }

      it "can call helper methods" do
        is_expected.to start_with "%PDF-1."
      end
    end
  end
end
