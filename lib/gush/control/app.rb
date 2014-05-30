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
        @cli = Gush::CLI.new

        keys = settings.redis.keys("gush.workflows.*")
        @workflows = keys.map do |key|
          id = key.sub("gush.workflows.", "")
          Gush.find_workflow(id, settings.redis)
        end
        slim :index
      end

      post "/run/:workflow" do |workflow|
        cli = Gush::CLI.new

        id = cli.create(workflow)
        cli.start(id)
        workflow = Gush.find_workflow(id, settings.redis)
        content_type :json
        {name: workflow.name, finished: 0, status: "Pending", total: workflow.nodes.count, id: id}.to_json
      end
    end
  end
end
