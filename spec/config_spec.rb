require 'spec_helper'
require_relative '../lib/unobtainium/config'

describe ::Unobtainium::Config do
  before :each do
    @data_path = File.join(File.dirname(__FILE__), 'data')
  end

  it "fails to load a nonexistent file" do
    expect { ::Unobtainium::Config.load_config("_nope_.yaml") }.to \
      raise_error Errno::ENOENT
  end

  it "is asked to load an unrecognized extension" do
    expect { ::Unobtainium::Config.load_config("_nope_.cfg") }.to \
      raise_error ArgumentError
  end

  it "loads a yaml config with a top-level hash correctly" do
    config = File.join(@data_path, 'hash.yml')
    cfg = ::Unobtainium::Config.load_config(config)

    expect(cfg["foo"]).to eql "bar"
    expect(cfg["baz"]).to eql "quux"
  end

  it "loads a yaml config with a top-level array correctly" do
    config = File.join(@data_path, 'array.yaml')
    cfg = ::Unobtainium::Config.load_config(config)

    expect(cfg["config"]).to eql %w(foo bar)
  end

  it "loads a JSON config correctly" do
    config = File.join(@data_path, 'test.json')
    cfg = ::Unobtainium::Config.load_config(config)

    expect(cfg["foo"]).to eql "bar"
    expect(cfg["baz"]).to eql 42
  end

  it "merges a hashed config correctly" do
    config = File.join(@data_path, 'hashmerge.yml')
    cfg = ::Unobtainium::Config.load_config(config)

    expect(cfg["asdf"]).to eql 1
    expect(cfg["foo.bar"]).to eql "baz"
    expect(cfg["foo.quux"]).to eql [1, 42]
    expect(cfg["foo.baz"]).to eql 3.14
    expect(cfg["blargh"]).to eql false
  end

  it "merges an array config correctly" do
    config = File.join(@data_path, 'arraymerge.yaml')
    cfg = ::Unobtainium::Config.load_config(config)

    expect(cfg["config"]).to eql %w(foo bar baz)
  end

  it "merges an array and hash config" do
    config = File.join(@data_path, 'mergefail.yaml')
    cfg = ::Unobtainium::Config.load_config(config)

    expect(cfg["config"]).to eql %w(array in main config)
    expect(cfg["local"]).to eql "override is a hash"
  end

  it "overrides configuration variables from the environment" do
    config = File.join(@data_path, 'hash.yml')
    cfg = ::Unobtainium::Config.load_config(config)

    ENV["BAZ"] = "override"
    expect(cfg["foo"]).to eql "bar"
    expect(cfg["baz"]).to eql "override"
  end

  it "treats an empty YAML file as an empty hash" do
    config = File.join(@data_path, 'empty.yml')
    cfg = ::Unobtainium::Config.load_config(config)
    expect(cfg).to be_empty
  end

  it "extends configuration hashes" do
    config = File.join(@data_path, 'driverconfig.yml')
    cfg = ::Unobtainium::Config.load_config(config)

    # First, test for non-extended values
    expect(cfg["drivers.root.rootoption"]).to eql 42
    expect(cfg["drivers.branch1.branch1option"]).to eql "foo"
    expect(cfg["drivers.branch2.branch2option"]).to eql "bar"
    expect(cfg["drivers.leaf.leafoption"]).to eql "baz"

    # Now test extended values
    expect(cfg["drivers.branch1.rootoption"]).to eql 42
    expect(cfg["drivers.branch2.rootoption"]).to eql 42
    expect(cfg["drivers.leaf.rootoption"]).to eql 42

    expect(cfg["drivers.branch2.branch1option"]).to eql "foo"
    expect(cfg["drivers.leaf.branch1option"]).to eql "override" # not "foo" !

    expect(cfg["drivers.leaf.branch2option"]).to eql "bar"

    # Also test that all levels go back to base == root
    expect(cfg["drivers.branch1.base"]).to eql 'root'
    expect(cfg["drivers.branch2.base"]).to eql 'root'
    expect(cfg["drivers.leaf.base"]).to eql 'root'
  end
end
