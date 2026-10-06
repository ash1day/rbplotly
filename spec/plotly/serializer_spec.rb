# frozen_string_literal: true

require "bigdecimal"
require "date"

RSpec.describe Plotly::Serializer do
  def dump(value) = described_class.dump(value)

  it "writes symbols as strings and keeps numbers, booleans and nil" do
    expect(dump({mode: :"markers+lines", n: [1, 2.5, true, nil]}))
      .to eq('{"mode":"markers+lines","n":[1,2.5,true,null]}')
  end

  it "writes NaN and infinities as null, which plotly.js draws as a gap" do
    expect(dump([1.0, Float::NAN, Float::INFINITY, -Float::INFINITY])).to eq("[1.0,null,null,null]")
  end

  it "writes times and dates in the format plotly.js reads as dates" do
    expect(dump([Date.new(2026, 10, 6)])).to eq('["2026-10-06"]')
    expect(dump([Time.new(2026, 10, 6, 9, 5, 7)])).to eq('["2026-10-06 09:05:07"]')
    expect(dump([Time.new(2026, 10, 6, 9, 5, 7.25r)])).to eq('["2026-10-06 09:05:07.25"]')
    expect(dump([DateTime.new(2026, 10, 6, 9, 5, 7)])).to eq('["2026-10-06 09:05:07"]')
  end

  it "converts other numeric types to floats" do
    expect(dump([BigDecimal("1.5"), 3r / 4])).to eq("[1.5,0.75]")
  end

  it "expands ranges, sets and other array-like objects such as data frame columns" do
    column = Struct.new(:values) { def to_a = values }.new([3, 4])
    expect(dump({x: 1..3, y: Set[1], z: column})).to eq('{"x":[1,2,3],"y":[1],"z":[3,4]}')
  end

  it "escapes text so that it cannot close the surrounding script element" do
    json = dump({text: "</script><script>alert(1)</script> "})
    expect(json).not_to include("<")
    expect(json).not_to include(" ")
    expect(JSON.parse(json)).to eq("text" => "</script><script>alert(1)</script> ")
  end

  it "keeps non-ASCII text readable" do
    expect(dump({title: "売上"})).to eq('{"title":"売上"}')
  end

  it "rejects values that have no JSON form" do
    expect { dump([Object.new]) }.to raise_error(TypeError, /cannot be written as plotly.js JSON/)
  end
end
