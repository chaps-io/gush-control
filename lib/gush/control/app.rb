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
          ws.onopen do
            settings.sockets[channel] ||= []
            settings.sockets[channel] << ws
          end

          ws.onmessage do |msg|
            EM.next_tick { settings.sockets[channel].each{|s| s.send(msg.to_json) } }
          end

          ws.onclose do
            settings.sockets[channel].delete(ws)
          end

          Thread.new do
            redis = Redis.new(url: Gush.configuration.redis_url)
            index = 0
            loop do
              logs = redis.lrange("gush.logs.#{channel}", index, index + 50)
              index += logs.size
              EM.next_tick{ settings.sockets[channel].each{|s| s.send(logs.to_json) } } if logs.any?
              sleep 1
            end
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

          ws.onclose do
            settings.sockets[channel].delete(ws)
          end

          Thread.new do
            redis = Redis.new(url: Gush.configuration.redis_url)
            redis.subscribe("gush.#{channel}") do |on|
              on.message do |redis_channel, message|
                EM.next_tick{ settings.sockets[channel].each{|s| s.send(message) } }
              end
            end
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

          ws.onclose do
            settings.sockets[:workers].delete(ws)
          end

          Thread.new do
            loop do
              data = ps.map{|process| {host: process["hostname"], pid: process["pid"], jobs: process["busy"] } }.to_json
              EM.next_tick{ settings.sockets[:workers].each{|s| s.send(data) } }
              sleep 5
            end
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

      post "/start/:workflow/?:job?" do |workflow, job|
        options = { redis: settings.redis }
        options[:jobs] = [job] if job

        Gush.start_workflow(workflow, options)
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
