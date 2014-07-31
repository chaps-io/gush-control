require 'logger'
require 'time'

module Gush
  module Control
    class Logger
      include ::Logger::Severity

      attr_accessor :level, :progname

      def initialize(redis, channel, level = DEBUG)
        @progname = nil
        @redis = redis
        @level = level
        @channel = channel
      end

      def add(severity = UNKNOWN, message = nil, prog = nil, &block)
        return true if severity < level

        if message.nil?
          if block_given?
            message = yield
          else
            message = prog
            prog = progname
          end
        end

        write(format_message(severity, prog || progname, message))
        true
      end
      alias log add

      def <<(message)
        write(message)
      end

      def debug(message = nil, &block)
        add(DEBUG, message, nil, &block)
      end

      def info(progname = nil, &block)
        add(INFO, nil, progname, &block)
      end

      def warn(progname = nil, &block)
        add(WARN, nil, progname, &block)
      end

      def error(progname = nil, &block)
        add(ERROR, nil, progname, &block)
      end

      def fatal(progname = nil, &block)
        add(FATAL, nil, progname, &block)
      end

      def unknown(progname = nil, &block)
        add(UNKNOWN, nil, progname, &block)
      end

      def close
        # noop
      end

      private

      LABELS = %w(DEBUG INFO WARN ERROR FATAL ANY)

      attr_reader :redis, :channel

      def write(message)
        redis.rpush(channel, message)
      end

      def format_message(severity, prog, message)
        current_time = Time.now.utc
        severity = LABELS[severity]
        "%s, [%s.%s #%s] %5s -- %s: %s\n" % [severity[0], current_time.iso8601, current_time.usec, $$, severity, prog, message]
      end
    end
  end
end
