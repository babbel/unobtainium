# coding: utf-8
#
# unobtainium
# https://github.com/jfinkhaeuser/unobtainium
#
# Copyright (c) 2016 Jens Finkhaeuser and other unobtainium contributors.
# All rights reserved.
#
module Unobtainium
  # @api private
  # Contains support code
  module Support
    # Contains code for dealing with instance identifiers.
    module Identifiers
      # Given a label and a set of options, generate a unique identifier
      # string.
      def identifier(scope, label, options = nil)
        caps = nil
        if options.has_key? "desired_capabilities"
          caps = options["desired_capabilities"]
        end
        if caps
          options = { desired_capabilities: caps }
        end
        digest = { label: label.to_sym, options: options }
        require 'digest/sha1'
        digest = Digest::SHA1.hexdigest(digest.to_s)
        return "#{scope}-#{digest}"
      end
    end # module Identifiers
  end # module Support
end # module Unobtainium
