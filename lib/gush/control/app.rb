module Gush
  module Control
    class App < Sinatra::Base
      get "/" do
        slim :index
      end

      post "/run/:workflow" do |workflow|
        cli = Gush::CLI.new

        id = cli.create(workflow)
        cli.start(id)

        id
      end
    end
  end
end
