module Gush
  module Control
    class App < Sinatra::Base
      get "/" do
        "Hello world"
      end
    end
  end
end
