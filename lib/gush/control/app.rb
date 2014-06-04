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

      register Sinatra::AssetPack

      assets {
        serve '/js',     from: 'assets/javascripts'
        serve '/css',    from: 'assets/stylesheets'
        serve '/images', from: 'assets/images'
      }

      get "/" do
        @workflows = Gush.all_workflows(settings.redis)
        slim :index
      end

      get '/subscribe/?:channel', provides: 'text/event-stream' do |channel|
        stream :keep_open do |out|
          redis = Redis.new(url: Gush.configuration.redis_url)
          redis.subscribe("gush.#{channel}") do |on|
            on.message do |channel, msg|
              if out.closed?
                redis.unsubscribe
                next
              end
              out << "data: #{msg}\n\n"
            end
          end
        end
      end

      get "/workers", provides: "text/event-stream" do
        require "sidekiq/api"
        ps = Sidekiq::ProcessSet.new

        stream :keep_open do |out|
          loop do
            data = ps.map{|process| {host: process["hostname"], pid: process["pid"], jobs: process["busy"] } }
            out << "data: #{data.to_json}\n\n"
            sleep 5
          end
        end
      end

      get "/show/:workflow" do |id|
        @workflow = Gush.find_workflow(id, settings.redis)
        @links = []
        @nodes = []
        @nodes << {name: "Start"}
        @nodes << {name: "End"}


        @workflow.nodes.each do |node|
          name = node.class.to_s
          @nodes << {name: name, finished: node.finished?, running: node.running?, failed: node.failed?}

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

      post "/start/:workflow" do |workflow|
        Gush.start_workflow(workflow, redis: settings.redis)
        content_type :json
        workflow.to_json
      end

      post "/create/:workflow" do |workflow|
        cli = Gush::CLI.new

        id = cli.create(workflow)
        workflow = Gush.find_workflow(id, settings.redis)
        content_type :json
        workflow.to_json
      end
    end
  end
end
