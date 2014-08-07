require 'capybara/rspec'
require 'capybara/webkit'
require 'bbq/spawn'
require 'gush/control'
require 'test_user'

Capybara.default_driver = :webkit
Capybara.app = Gush::Control::App

Gush.configure do |config|
  config.redis_url = 'redis://127.0.0.1:33333'
  config.gushfile  = 'spec/Gushfile.rb'
end

module SpecHelpers
  def user
    TestUser.new
  end

  def redis
    Redis.new(url: 'redis://127.0.0.1:33333')
  end
end

RSpec.configure do |config|
  include SpecHelpers

  orchestrator = Bbq::Spawn::Orchestrator.new
  config.before(:suite) do
    redis_server = Bbq::Spawn::Executor.new(*%w(redis-server spec/redis.conf))
    orchestrator.coordinate(redis_server, host: '127.0.0.1', port: 33333)

    workers = Bbq::Spawn::Executor.new(*%w(bundle exec gush workers -f spec/Gushfile.rb))
    orchestrator.coordinate(workers, banner: "Starting processing, hit Ctrl-C to stop")
    orchestrator.start
  end

  config.after(:suite) do
    orchestrator.stop
  end

  config.after(:each) do
    redis.flushdb
  end
end
