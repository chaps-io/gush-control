module Gush
  class CLI < Thor
    desc "server [options]", "Start server"
    option :port
    def server
      puts "Starting server!"
      Thin::Runner.new(["start", "-R", Gush::Control.rackup_path.to_s]).run!
    end
  end
end
