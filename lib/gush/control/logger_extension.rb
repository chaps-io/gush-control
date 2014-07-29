require 'gush/control/logger'

require 'gush/control'

module Gush
  module Control
    class LoggerBuilder < Gush::LoggerBuilder
      def build
        Logger.new(Redis.new(url: Gush.configuration.redis_url), "gush.logs.#{workflow.id}.#{job.name}")
      end
    end
  end
end

class Gush::Workflow
  def default_logger_builder
    Gush::Control::LoggerBuilder
  end
end
