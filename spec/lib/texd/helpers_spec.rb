# frozen_string_literal: true

RSpec.describe Texd::Helpers do
  subject(:view_mock) { Class.new { include Texd::Helpers }.new }

  def expect_escape(input, **rest)
    expect view_mock.escape(input, **rest)
  end

  it "handles nil values" do
    expect_escape(nil).to eq ""
  end

  it "escapes dollar and linebreak" do
    expect_escape("foo$\nbar").to eq "foo\\$\\\\bar"
  end

  it "quotes" do
    expect_escape("\"double\" and 'single' quotes").to eq \
      "\\glqq{}double\\grqq{} and \\glq{}single\\grq{} quotes"
  end

  it "doesn't quote egde case" do
    expect_escape(%q("O'Neill", they shouted, "don't go 'there'".)).to eq \
      "\\glqq{}O'Neill\\grqq{}, they shouted, \\glqq{}don't go \\glq{}there\\grq{}\\grqq{}."
  end

  it "disables typographic replacements" do
    input = '"info@with-hyphen.example.com"'

    expect_escape(input).to eq '\glqq{}info@with"=hyphen.example.com\grqq{}'
    expect_escape(input, typographic: false).to eq input
  end
end
