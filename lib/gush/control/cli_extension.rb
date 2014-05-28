module Gush
  class CLI < Thor
    desc "server [options]", "Start server"
    option :port
    def server
      puts "Starting server!"
      Thin::Runner.new(["start"]).run!
    end
  end
end
