lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "gush/control"

$connections = []

Thread.new do
  redis = Redis.new(url: Gush.configuration.redis_url)
  redis.psubscribe('gush.*') do |on|
    on.pmessage do |match, channel, message|
      $connections.each do |connection|
        name, out = connection
        next if name != channel.gsub("gush.", "")
        out << "data: #{message}\n\n"
      end
    end
  end
end

map "/" do
  run Gush::Control::App
end
