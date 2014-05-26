module Gush
  module Control
    class App < Sinatra::Base
      get "/" do
        slim :index
      end
    end
  end
end
