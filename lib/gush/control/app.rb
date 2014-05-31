classes = %w{FetchA Middle FetchB PersistA PersistB Normalize}

classes.each do |name|
  eval <<-CODE
    class #{name} < Gush::Job
      def work
        raise "fail" if #{name} == Normalize
        sleep rand(0.5..5)
      end
    end
  CODE
end

class Workflow < Gush::Workflow
  def configure
    run FetchA
    run FetchB

    run Middle,
      after: [FetchA, FetchB],
      before: [PersistA, PersistB]

    run PersistA
    run PersistB
    run Normalize, after: [PersistA, PersistB]
  end
end

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
        @nodes = []
        @nodes << {index: 0, x: 20, y: 250,  weight: 10, name: "Start"}
        @nodes << {index: 1, x: 840, y: 250, weight: 10, name: "End"}


        @workflow.nodes.each do |node|
          name = node.class.to_s
          if node.incoming.empty?
            @links << {source: "Start", target: name, type: "flow"}
          end

          node.outgoing.each do |out|
            @links << {source: name, target: out, type: "flow"}
          end

         if node.outgoing.empty?
            @links << {source: name, target: "End", type: "flow"}
          end
        end
        slim :show
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
