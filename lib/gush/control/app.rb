module Gush
  module Control
    class App < Sinatra::Base
      set :server, :thin
      set :redis, Redis.new(url: Gush.configuration.redis_url)
      set :sockets, {}

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

      get "/jobs/:workflow_id.:job" do |workflow_id, job|
        @workflow = Gush.find_workflow(workflow_id, settings.redis)
        @job = @workflow.find_job(job)
        slim :job
      end

      get '/logs/?:channel' do |channel|
        request.websocket do |ws|
          commands = Queue.new
          redis = Redis.new(url: Gush.configuration.redis_url)
          tid = LogSender.new(settings,
                              redis,
                              commands,
                              channel).run

          ws.onopen do
            settings.sockets[channel] ||= []
            settings.sockets[channel] << ws
          end

          ws.onmessage do |msg|
            commands.push(msg)
          end

          ws.onclose do
            settings.sockets[channel].delete(ws)
            Thread.kill(tid)
          end

        end
      end

      get '/subscribe/?:channel' do |channel|
        channel = channel.to_sym
        request.websocket do |ws|
          ws.onopen do
            settings.sockets[channel] ||= []
            settings.sockets[channel] << ws
          end

          ws.onmessage do |msg|
            EM.next_tick { settings.sockets[channel].each{|s| s.send(msg.to_json) } }
          end

          tid = Thread.new do
            redis = Redis.new(url: Gush.configuration.redis_url)
            redis.subscribe("gush.#{channel}") do |on|
              on.message do |redis_channel, message|
                EM.next_tick{ settings.sockets[channel].each{|s| s.send(message) } }
              end
            end
          end

          ws.onclose do
            settings.sockets[channel].delete(ws)
            Thread.kill(tid)
          end
        end
      end

      get "/workers" do
        require "sidekiq/api"
        ps = Sidekiq::ProcessSet.new

        request.websocket do |ws|
          ws.onopen do
            settings.sockets[:workers] ||= []
            settings.sockets[:workers] << ws
          end

          tid = Thread.new do
            loop do
              data = ps.map{|process| {host: process["hostname"], pid: process["pid"], jobs: process["busy"] } }.to_json
              EM.next_tick{ settings.sockets[:workers].each{|s| s.send(data) } }
              sleep 5
            end
          end

          ws.onclose do
            settings.sockets[:workers].delete(ws)
            Thread.kill(tid)
          end
        end
      end

      get "/show/:workflow.?:format?" do |id, format|
        @workflow = Gush.find_workflow(id, settings.redis)

        if format == "json"
          content_type :json
          return @workflow.to_json
        end

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

      post "/start/:workflow/?:job?" do |workflow, job|
        options = { redis: settings.redis }
        options[:jobs] = [job] if job

        Gush.start_workflow(workflow, options)
        content_type :json
        workflow.to_json
      end

      post "/stop/:workflow" do |workflow|
        options = { redis: settings.redis }

        Gush.stop_workflow(workflow, options)
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

      post "/destroy/:workflow" do |id|
        workflow = Gush.find_workflow(id, settings.redis)
        Gush.destroy_workflow(workflow, settings.redis)
        {status: "ok"}.to_json
      end
    end
  end
end
