class LogSender
  ROWS = 25

  def initialize(settings, redis, commands, channel)
    @redis = redis
    @commands = commands
    @channel = channel
    @settings = settings
  end

  def run
    Thread.new do
      tail = message_count - ROWS
      head = (tail - 1).downto(0).each_slice(ROWS)

      loop do
        if commands.empty?
          method = :append
          logs = fetch_logs_after(tail)
          tail += logs.size
        else
          case commands.pop
          when 'prepend'
            method = :prepend
            begin
              logs = fetch_range(head.next)
            rescue StopIteration
              logs = []
            end
          end
        end

        send_lines(logs, method)
        sleep 1
      end
    end
  end

  private

  def send_lines(logs, method)
    data = {lines: logs, method: method}.to_json
    EM.next_tick{ settings.sockets[channel].each{|s| s.send(data) } } if logs.any?
  end

  def message_count
    redis.llen(redis_key)
  end

  def fetch_logs_after(idx)
    redis.lrange(redis_key, idx, idx + ROWS)
  end

  def fetch_range(r)
    redis.lrange(redis_key, r.last, r.first).reverse
  end

  def redis_key
    "gush.logs.#{channel}"
  end

  attr_reader :channel, :redis, :commands, :settings
end
