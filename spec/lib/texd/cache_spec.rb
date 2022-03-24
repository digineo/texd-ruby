# frozen_string_literal: true

RSpec.describe Texd::Cache do
  subject(:cache) { Texd::Cache.new(3) }

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

    expect(cache.keys).to include(:two, :three, :four)

    cache.read(:two)
    cache.read(:four)
    cache.write(:five, "5")
    expect(cache.keys).to include(:two, :four, :five)
  end

  describe "#write" do
    it "returns the value" do
      [1, :a, "b", Time.now].each do |v|
        expect(cache.write(:v, v)).to be v
      end
    end

    it "does not duplicate values" do
      ref = { a: 1, b: 2 }
      cache.write(:ref, ref)

      ref.merge! c: 3
      expect(cache.read(:ref)).to include(c: 3)
    end
  end

  context "arrays as keys" do
    it "are allowed" do
      cache.write([1, :a], "1a")
      cache.write([2, :b], "2b")
      cache.write([3, :c], "3c")
      expect(cache.keys).to include([1, :a], [2, :b], [3, :c])

      expect(cache.read([2, :b])).to eq "2b"
      expect(cache.read([4, :d])).to be_nil

      cache.write([4, :d], "4d")
      expect(cache.keys).to include([2, :b], [3, :c], [4, :d])
    end
  end

  describe "#fetch" do
    it "block is evaluated once" do
      one = cache.fetch(:same_key) { 1 }
      two = cache.fetch(:same_key) { 2 }
      expect(cache.count).to eq 1
      expect([one, two]).to match [1, 1]
    end

    it "fills the cache" do
      cache.fetch(:one) { 1 }
      cache.fetch(:two) { 2 }
      cache.fetch(:three) { 3 }
      expect(cache.count).to eq 3
      expect(cache.keys).to include(:one, :two, :three)

      cache.fetch(:four) { 4 }
      cache.fetch(:two) { 2 }
      expect(cache.count).to eq 3
      expect(cache.keys).to include(:two, :three, :four)
    end
  end
end
