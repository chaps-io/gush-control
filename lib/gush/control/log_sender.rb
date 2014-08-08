class LogSender
  ROWS = 25

  def initialize(socket, redis, commands, channel)
    @redis = redis
    @commands = commands
    @channel = channel
    @socket = socket
  end

  def run
    Thread.new do
      tail = [0, message_count - ROWS].max
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

        send_lines(sanitize_logs(logs), method)
        sleep 1
      end
    end
  end

  private

  def send_lines(logs, method)
    data = {lines: logs, method: method}.to_json
    EM.next_tick{ socket.send(data) } if logs.any?
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

  def sanitize_logs(lines)
    lines.map {|l| Rack::Utils.escape_html(l) }
  end

  attr_reader :channel, :redis, :commands, :socket
end
