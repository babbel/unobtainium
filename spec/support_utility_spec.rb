require 'spec_helper'
require_relative '../lib/unobtainium/support/util'

# this is the Tester class
class Tester
  LABELS = {
    noalias: [],
    aliases: %i[foo bar],
    conflict: %i[bar]
  }.freeze

  extend ::Unobtainium::Support::Utility
end # class Tester

describe ::Unobtainium::Support::Utility do
  it "returns nil for a label that can't be matched" do
    expect(Tester.normalize_label("nomatch")).to be_nil
    expect(Tester.normalize_label(:nomatch)).to be_nil
  end

  it "normalizes a string label" do
    expect(Tester.normalize_label("noalias")).to eql :noalias
  end

  it "normalizes an alias" do
    expect(Tester.normalize_label("foo")).to eql :aliases
  end

  it "returns the first match on alias conflicts" do
    expect(Tester.normalize_label("bar")).to eql :aliases
  end
end
