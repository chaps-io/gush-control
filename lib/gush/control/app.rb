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

      get "/show/:workflow" do |id|
        @workflow = Gush.find_workflow(id, settings.redis)
        @links = []
        @workflow.nodes.each do |node|
          if node.incoming.empty?
            @links << {source: "Start", target: node.class.to_s, type: "flow"}
          end

          node.outgoing.each do |out|
            @links << {source: node.class.to_s, target: out, type: "flow"}
          end

         if node.outgoing.empty?
            @links << {source: node.class.to_s, target: "End", type: "flow"}
          end
        end
        slim :show
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
