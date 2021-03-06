# coding: utf-8

# unobtainium
# https://github.com/jfinkhaeuser/unobtainium
# Copyright (c) 2016 Jens Finkhaeuser and other unobtainium contributors.
# All rights reserved.

module Unobtainium
  # @api private
  # Contains support code
  module Support
    ##
    # Utility code shared by driver implementations
    module Utility
      ##
      # For a recognized label alias, returns a normalized label. Requires
      # the enclosing class to provide a LABELS connstant that is a hash
      # where keys are the normalized label, and the value is an array of
      # aliases:
      #
      # ```ruby
      #   LABELS = {
      #     foo: [:alias1, :alias2],
      #     bar: [],
      #   }.freeze
      # ```
      #
      # Empty aliases means that there are no aliases for this label.
      #
      # @param label [String, Symbol] the driver label to normalize
      def normalize_label(label)
        sym_label = label.to_sym
        self::LABELS.each do |normalized, aliases|
          if sym_label == normalized or aliases.include?(sym_label)
            return normalized
          end
        end
        return nil
      end

      def clean_chrome_args(options)
        optionscopy = ::Collapsium::Config::Configuration.new(options)
        %i[desired_capabilities caps].each do |index|
          begin
            optionscopy[index]["chromeOptions"]["args"].uniq!
          rescue NoMethodError # rubocop:disable Lint/HandleExceptions
          end
        end
        optionscopy
      end

      def transform_string_to_symbol_index(options)
        if options.nil? || options.keys.all? { |key| key.class.name == 'Symbol' }
          # nothing to do, options are nil, or all keys are symbols already
          return options
        end
        optionscopy = ::Collapsium::Config::Configuration.new(options)
        options.keys.each do |key|
          if key.class.name == 'Symbol'
            next
          end
          optionscopy.delete key
          optionscopy[key.to_sym] = options[key]
        end
        optionscopy
      end

    end # module Utility
  end # module Support
end # module Unobtainium
