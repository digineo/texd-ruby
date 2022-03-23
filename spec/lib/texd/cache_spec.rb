# frozen_string_literal: true

RSpec.describe Texd::Cache do
  let(:cache) { Texd::Cache.new(3) }

  it "empty cache" do
    expect(cache.count).to eq 0
    expect(cache.read(:one)).to eq nil
  end

  it "filling cache" do
    cache.write(:one, "1")
    expect(cache.count).to eq 1
    expect(cache.read(:one)).to eq "1"

    cache.write(:one, "11")
    expect(cache.count).to eq 1
    expect(cache.read(:one)).to eq "11"

    cache.write(:two, "2")
    cache.write(:three, "3")
    expect(cache.count).to eq 3

    cache.write(:four, "4")
    expect(cache.count).to eq 3

    expect(cache.hash.keys).to include(:two, :three, :four)

    cache.read(:two)
    cache.read(:four)
    cache.write(:five, "5")
    expect(cache.hash.keys).to include(:two, :four, :five)
  end
end
