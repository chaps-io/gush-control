module Gush
  module Control
    class App < Sinatra::Base
      set :server, :thin
      set :client, Gush::Client.new
      set :sockets, {}

      register Sinatra::AssetPack

      assets {
        serve '/js',     from: 'assets/javascripts'
        serve '/css',    from: 'assets/stylesheets'
        serve '/images', from: 'assets/images'
      }

      get "/" do
        @workflows = settings.client.all_workflows
        slim :index
      end

      get "/jobs/:workflow_id.:job" do |workflow_id, job|
        @workflow = settings.client.find_workflow(workflow_id)
        @job = @workflow.find_job(job)
        slim :job
      end

      get '/logs/?:channel' do |channel|
        request.websocket do |ws|
          commands = Queue.new
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
        @workflow = settings.client.find_workflow(id)

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
        settings.client.start_workflow(workflow, Array(job))
        content_type :json
        workflow.to_json
      end

      post "/stop/:workflow" do |workflow|
        settings.client.stop_workflow(workflow)
        content_type :json
        workflow.to_json
      end

      post "/create/:workflow" do |name|
        workflow = settings.client.create_workflow(name)
        content_type :json
        workflow.to_json
      end

      post "/destroy/:workflow" do |id|
        workflow = settings.client.find_workflow(id)
        remove_workflow_and_logs(workflow)
        {status: "ok"}.to_json
      end

      post "/purge_logs/:channel" do |channel|
        remove_logs_in_channel(channel)

        {status: "ok"}.to_json
      end

      post "/purge" do
        completed = settings.client.all_workflows.select(&:finished?)
        completed.each {|workflow| remove_workflow_and_logs(workflow) }

        {status: "ok"}.to_json
      end

      private

      def redis
        Thread.current[:redis] ||= Redis.new(url: settings.client.configuration.redis_url)
      end

      def remove_workflow_and_logs(workflow)
        remove_workflow(workflow)
        remove_logs(workflow)
      end

      def remove_workflow(workflow)
        settings.client.destroy_workflow(workflow)
      end

      def remove_logs(workflow)
        redis.keys("gush.logs.#{workflow.id}.*").each {|key| redis.del(key) }
      end

      def remove_logs_in_channel(channel)
        redis.del("gush.logs.#{channel}")
      end
    end
  end
end
