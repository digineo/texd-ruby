# frozen_string_literal: true

require "spec_helper"

RSpec.describe Texd do
  describe "#render" do
    subject(:result) { described_class.render(**render_args) }

    let(:render_args) { { template: "documents/document" } }

    it { is_expected.to start_with "%PDF-1." }

    def reconfigure!(**knobs)
      config = Texd.config.to_h.merge(knobs)
      allow(Texd).to receive(:config).and_return(Texd::Configuration.new(**config))
    end

    context "with alternative layout" do
      let(:render_args) { { template: "documents/document", layout: "alternative" } }

      it { is_expected.to start_with "%PDF-1." }
    end

    context "without layout" do
      let(:render_args) { { template: "documents/standalone", layout: false } }

      it { is_expected.to start_with "%PDF-1." }
    end

    context "with broken input" do
      let(:render_args) { { template: "broken/missing" } }

      def expect_compilation_error
        subject
        yield nil
      rescue Texd::Client::CompilationError => err
        yield err
      rescue StandardError => err
        expect(err).to be_a Texd::Client::CompilationError
      end

      it "raises an error" do
        expect { result }.to raise_error Texd::Client::CompilationError
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
            "output" => a_string_matching(/try to force complete processing/),
          )
        end
      end

      it "can ignore errors" do
        reconfigure!(error_format: "condensed", error_handler: "ignore")

        expect { result }.not_to raise_error
      end

      it "can log errors" do
        reconfigure!(error_format: "condensed", error_handler: "stderr")

        expect { result }.to output(<<~LOG).to_stderr
          Compilation failed: compilation failed
          Logs:
          LaTeX Error: File `missing.tex' not found.
          Emergency stop.
        LOG
      end

      it "can log details" do
        reconfigure!(error_format: "json", error_handler: "stderr")

        expect {
          expect(result).to be_blank
        }.to output(/Logs: not available/).to_stderr
      end

      it "can handle errors" do
        reconfigure!(error_format: "condensed", error_handler: ->(err, doc) {
          expect(err).to be_a(Texd::Client::CompilationError)
          expect(doc).to be_a(Texd::Document::Compilation)

          expect(err.logs).to include "File `missing.tex' not found"
          expect(doc.main_input_contents).to include "\\input{missing}"

          raise ArgumentError, "reraised"
        })

        expect {
          expect(result).to be_blank
        }.to raise_error ArgumentError, "reraised"
      end
    end

    context "with custom helper" do
      let(:render_args) { { template: "my_helper/doc" } }

      let(:my_helper) {
        Module.new {
          def my_helper_method
            42
          end
        }
      }

      it "can call helper methods" do
        reconfigure! helpers: Set[my_helper]
        expect(result).to start_with "%PDF-1."
      end
    end

    context "with locals" do
      let(:render_args) {
        {
          template: "my_helper/doc",
          locals:   { my_helper_method: "21\\times 2" },
        }
      }

      it "can call helper methods" do
        expect(result).to start_with "%PDF-1."
      end
    end
  end
end
