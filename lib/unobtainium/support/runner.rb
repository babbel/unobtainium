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
    # Runs a shell command and detaches. Offers methods for managing the process
    # lifetime. Implements #destroy, so you can use it with the Runtime class to
    # kill the shell command upon script end.
    class Runner
      # @return [String] the ID passed to the constructor
      attr_reader :id

      # @return [Array] the command passed to the constructor
      attr_reader :command

      # @return [Integer] if the command is started, the pid of the process,
      #     or nil otherwise.
      attr_reader :pid

      # @return [IO] if the command is started, an IO object to read the
      #     commands output from, or nil otherwise.
      attr_reader :stdout

      # @return [IO] if the command is started, an IO object to read the
      #     commands error output from, or nil otherwise.
      attr_reader :stderr

      ##
      # Initialize with a shell command, but do not run yet.
      #
      # @param id [String] a unique ID for the command. This is to differentiate
      #     multiple similar commands from each other.
      # @param command [Array] the remaining parameters are the command and its
      #     arguments.
      def initialize(id, *command)
        if command.empty?
          raise ArgumentError, "Command may not be empty!"
        end

        @id = id
        @command = command
        @pid = nil
        @stdout = nil
        @stderr = nil
        @wout = nil
        @werr = nil
      end

      ##
      # Start the command. Afterwards, #pid, #stdout, and #stderr should be
      # non-nil.
      # @return [Integer] the pid of the command process
      def start
        if not @pid.nil?
          raise "Command already running!"
        end

        # Reset everything
        reset

        # Capture options; pipes for stdout and stderr
        @stdout, @wout = IO.pipe
        @stderr, @werr = IO.pipe
        opts = {
          out: @wout,
          err: @werr,
        }

        @pid = spawn({}, *@command, opts)
        return @pid
      end

      ##
      # Resets stdout, stderr, etc. - does not kill a process, see #kill
      # instead.
      def reset
        cleanup(true)
      end

      ##
      # Wait for the command to exit.
      # @return [Process::Status] exit status of the command.
      def wait
        _, status = Process.wait2(@pid)
        cleanup
        return status
      end

      ##
      # Send the "KILL" signal to the command process and all its children
      def kill
        signal("KILL", scope: :all)
        cleanup
      end

      ##
      # Send the given signal to the process, and/or it's children.
      # @param signal [String] the signal to send
      # @param scope [Symbol] one of :self (the command process),
      #     :children (it's children *only) or :all (the process and its
      #     children.
      def signal(signal, scope: :self)
        if @pid.nil?
          raise "No command is running!"
        end

        if not %i[self children all].include?(scope)
          raise ArgumentError, "The :scope argument must be one of :self, "\
              ":children or :all!"
        end

        # Figure out which pids to send the signal to. That is usually @pid,
        # but possibly its children.
        to_send = []
        if %i[self all].include?(scope)
          to_send << @pid
        end

        if %i[children all].include?(scope)
          pid = Process.pid
          pipe = IO.popen("ps -ef | grep #{pid}")
          child_pids = pipe.readlines.map do |line|
            parts = line.split(/\s+/)
            parts[2] if parts[3] == pid.to_s and parts[2] != pipe.pid.to_s
          end.compact
          to_send += child_pids.collect(&:to_i)
        end

        # Alright, send the signal!
        to_send.each do |current_pid|
          begin
            Process.kill(signal, current_pid)
          rescue Exception => e # rubocop:disable Lint/RescueException
            puts e
            # If the kill didn't work, we don't really care.
          end
        end
      end

      ##
      # (see #kill)
      # Use together with Runtime class to clean up any commands at exit.
      def destroy
        kill
        reset
      end

      private

      def close(channel)
        channel&.close
      end

      def cleanup(all = false)
        @pid = nil

        close @wout
        @wout = nil
        close @werr
        @werr = nil

        unless all
          return
        end

        close @stdout
        @stdout = nil
        close @stderr
        @stderr = nil
      end
    end # class Runner
  end # module Support
end # module Unobtainium
