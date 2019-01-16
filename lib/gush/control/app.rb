require "sidekiq/api"
require "sprockets"

module Gush
  module Control
    class App < Sinatra::Base
      enable :logging
      set :server, :thin
      set :client, proc { Gush::Client.new }
      set :environment, Sprockets::Environment.new(File.dirname(__FILE__))

      environment.append_path "assets/stylesheets"
      environment.append_path "assets/javascripts"
      environment.js_compressor  = :uglify
      environment.css_compressor = :scss

      get %r{/(js|css)/.+} do |asset_type|
        env["PATH_INFO"].sub!("/#{asset_type}", "")
        settings.environment.call(env)
      end

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
          tid = LogSender.new(ws,
                              redis,
                              commands,
                              channel).run

          ws.onmessage do |msg|
            commands.push(msg)
          end

          ws.onclose do
            Thread.kill(tid)
          end
        end
      end

      get '/subscribe/?:channel' do |channel|
        channel = channel.to_sym
        request.websocket do |ws|
          ws.onmessage do |msg|
            EM.next_tick { ws.send(msg.to_json) }
          end

          tid = Thread.new do
            redis.subscribe("gush.#{channel}") do |on|
              on.message do |redis_channel, message|
                EM.next_tick{ ws.send(message) }
              end
            end
          end

          ws.onclose do
            Thread.kill(tid)
          end
        end
      end

      get "/workers" do
        ps = Sidekiq::ProcessSet.new

        request.websocket do |ws|
          tid = Thread.new do
            loop do
              data = ps.map{|process| {host: process["hostname"], pid: process["pid"], jobs: process["busy"] } }.to_json
              EM.next_tick{ ws.send(data) }
              sleep 5
            end
          end

          ws.onclose do
            Thread.kill(tid)
          end
        end
      end

      get "/show/:workflow.?:format?" do |id, format|
        @workflow = settings.client.find_workflow(id)


        @links = []
        @jobs = []
        @jobs << {name: "Start", klass: "Start"}
        @jobs << {name: "End", klass: "End"}


        @workflow.jobs.each do |job|
          @jobs << {
            name:         job.name,
            klass:        job.class.to_s,
            finished:     job.finished?,
            started_at:   format_time(job.started_at),
            finished_at:  format_time(job.finished_at),
            running:      job.running?,
            enqueued:     job.enqueued?,
            failed:       job.failed?
          }

          if job.incoming.empty?
            @links << {source: "Start", target: job.name, type: "flow"}
          end

          job.outgoing.each do |out|
            @links << {source: job.name, target: out, type: "flow"}
          end

          if job.outgoing.empty?
            @links << {source: job.name, target: "End", type: "flow"}
          end
        end

        if format == "json"
          content_type :json
          return { jobs: @jobs, links: @links }.to_json
        end

        slim :show
      end

      post "/start/:workflow/?:job?" do |id, job|
        workflow = settings.client.find_workflow(id)
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

      def format_time(timestamp)
        Time.at(timestamp) if timestamp
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
