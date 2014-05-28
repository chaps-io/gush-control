module Gush
  module Control
    class App < Sinatra::Base
      set :sockets, []
      set :server, :thin
      set :redis, Redis.new(url: Gush.configuration.redis_url)
      set :pubsub_namespace, "gush"

      register Sinatra::PubSub
      register Sinatra::AssetPack

      assets {
        serve '/js',     from: 'assets/javascripts'
        serve '/css',    from: 'assets/stylesheets'
        serve '/images', from: 'assets/images'
      }

      get "/" do
        slim :index
      end

      post "/run/:workflow" do |workflow|
        cli = Gush::CLI.new

        id = cli.create(workflow)
        cli.start(id)
        content_type :json
        {name: workflow, id: id}.to_json
      end
    end
  end
end
