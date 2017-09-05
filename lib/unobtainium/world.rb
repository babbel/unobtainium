# coding: utf-8

# unobtainium
# https://github.com/jfinkhaeuser/unobtainium
# Copyright (c) 2016 Jens Finkhaeuser and other unobtainium contributors.
# All rights reserved.

require 'unobtainium'

require 'collapsium-config'

require 'unobtainium/driver'
require 'unobtainium/runtime'
require 'unobtainium/support/identifiers'
require 'unobtainium/support/util'

module Unobtainium
  ##
  # The World module combines other modules, defining simpler entry points
  # into the gem's functionality.
  module World

    ##
    # Modules can have class methods, too, but it's a little more verbose to
    # provide them.
    module ClassMethods
      # Configuraiton loading options
      DEFAULT_CONFIG_OPTIONS = {
        resolve_extensions: true,
        nonexistent_base: :extend,
      }.freeze

      # Set the configuration file
      def config_file=(name)
        ::Collapsium::Config.config_file = name
      end

      # @return [String] the config file path, defaulting to 'config/config.yml'
      def config_file
        return ::Collapsium::Config.config_file
      end

      # In order for Unobtainium::World to include Collapsium::Config
      # functionality, it has to be inherited when the former is
      # included...
      def included(klass)
        set_config_defaults

        klass.class_eval do
          include ::Collapsium::Config
        end
      end

      # ... and when it's extended.
      def extended(world)
        # :nocov:
        set_config_defaults

        world.extend(::Collapsium::Config)
        # :nocov:
      end

      def set_config_defaults
        # Override collapsium-config's default config path
        if ::Collapsium::Config.config_file == \
           ::Collapsium::Config::DEFAULT_CONFIG_PATH
          ::Collapsium::Config.config_file = 'config/config.yml'
        end

        if ::Collapsium::Config.config_options == \
           ::Collapsium::Config::DEFAULT_CONFIG_OPTIONS
          ::Collapsium::Config.config_options = DEFAULT_CONFIG_OPTIONS
        end
      end
    end # module ClassMethods
    extend ClassMethods

    include ::Unobtainium::Support::Identifiers
    include ::Unobtainium::Support::Utility

    ##
    # (see Driver#create)
    #
    # Returns a driver instance with the given options. If no options are
    # provided, options from the global configuration are used.
    def driver(label = nil, options = nil)
      # Resolve unique options
      label, options = resolve_options(label, options)

      # Create a key for the label and options. This should always
      # return the same key for the same label and options.
      key = options['unobtainium_instance_id']
      if key.nil?
        key = identifier('driver', label, options)
      end

      # Only create a driver with this exact configuration once. Unfortunately
      # We'll have to bind the destructor to whatever configuration exists at
      # this point in time, so we have to create a proc here - whether the Driver
      # gets created or not.
      at_end = config.fetch("at_end", "quit")
      dtor = proc do |the_driver|
        # :nocov:
        if the_driver.nil?
          return
        end

        # We'll rescue Exception here because we really want all destructors
        # to run.
        # rubocop:disable Lint/RescueException
        begin
          meth = at_end.to_sym
          the_driver.send(meth)
        rescue Exception => err
          puts "Exception in destructor: [#{err.class}] #{err}"
        end
        # rubocop:enable Lint/RescueException
        # :nocov:
      end

      ::Unobtainium::Runtime.instance.store_with_if(key, dtor) do
        ::Unobtainium::Driver.create(label, options)
      end
    end

    private

    ##
    # The merged/extended options might define a "base"; that's the label
    # we need to use.
    def replace_label_with_base_label_if_necessary(orig_label, options)
      if options.nil? || options["base"].nil?
        return orig_label
      end

      bases = options["base"]

      # Collapsium config returns an Array of bases, but we really only want
      # one. We'll have to do the sensible thing and only use one of the bases
      # which also is a driver for the label. Since there's no better choice,
      # let's default to the first of those.
      bases.each do |base|
        unless base.start_with?(".drivers.")
          next
        end
        return base.gsub(/^\.drivers\./, '')
      end
    end

    ##
    # World's own option resolution ensures that the same options always get
    # resolved the same, by storing anything resolved from Driver in the Runtime
    # instance (i.e. asking the Driver only once per unique set of label and
    # options).
    def resolve_options(label, options)
      # Make sure we have a label for the driver
      if label.nil?
        label = config["driver"]
      end

      # Make sure we have options matching the driver
      if options.nil?
        options = config["drivers.#{label}"]
        options = clean_chrome_args options
      end

      label = replace_label_with_base_label_if_necessary(label, options)
      # if there are options and options has the 'base' key, delete it
      # since this is an UberHash, deleting a nonexistend property returns 'nil'
      options.delete("base")

      # we really need :caps and "desired_capabilities" in our options
      unless options.has_key?(:caps)
        options[:caps] = options["desired_capabilities"]
      end
      unless options.key?("desired_capabilities")
        options["desired_capabilities"] = options[:caps]
      end

      label, options, _ = ::Unobtainium::Driver.resolve_options(label, options)
      begin
        options.delete :args
        options.delete :prefs
      rescue KeyError
      end
      options = clean_chrome_args options
      option_key = identifier('options', label, options)

      # Do we have options already resolved?
      # then we take what we already have together with the options from the
      # input and make new options, but store it under the original key
      # assuming that the key is constructed form the input options
      begin
        stored_opts = ::Unobtainium::Runtime.instance.fetch(option_key)
        options = ::Collapsium::UberHash.new(options)
        options.recursive_merge!(stored_opts)
        options = clean_chrome_args options
      rescue KeyError # rubocop:disable Lint/HandleExceptions
      end

      # The driver may modify the options; if so, we should let it do that
      # here. That way our key (below) is based on the expanded options.
      ::Unobtainium::Runtime.instance.store(option_key, options)

      return label, options
    end

  end # module World

end # module Unobtainium
