require "pathname"
require "thin"
require "sinatra"
require "coffee-script"
require "slim"
require "gush"
require "sinatra-websocket"
require "sinatra/pubsub"
require "sinatra/assetpack"
require "gush/control/version"
require "gush/control/app"
require "gush/control/cli_extension"

module Gush
  module Control
    def self.rackup_path
      Pathname(__FILE__).dirname.parent.parent.join("config.ru")
    end
  end
end
