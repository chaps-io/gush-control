module Gush
  class CLI < Thor
    desc "server [options]", "Start server"
    option :port, aliases: "-p", default: "3000"
    option :address, aliases: "-a", default: "0.0.0.0"
    option :daemonize, aliases: "-d"

    def server
      Thin::Runner.new(params_to_args(thin_params(options))).run!
    end

    private
    def thin_params(options)
      { rackup: Gush::Control.rackup_path.to_s, port: options[:port], address: options[:address] }.tap do |params|
        params.merge!(daemonize: true) if options[:daemonize]
      end
    end

    def params_to_args(params)
      params.flat_map{|k, v| ["--#{k}", v] }.unshift("start")
    end
  end
end
