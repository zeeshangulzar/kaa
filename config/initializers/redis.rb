host =
  if Rails.env.to_s == 'development'
    'localhost'
  else
    if !!defined?(IS_STAGING) && IS_STAGING
      # someday change to resque.staging.hesapps.com
      'resque.staging2.hesapps.com'
    else
      'resque.hesapps.com'
    end
  end

redis_connection = Redis.new(:host => host, :port => 6379)
Resque.redis = redis_connection
Resque.redis.namespace = "#{APPLICATION_NAME}:resque"
$redis = Redis::Namespace.new("#{APPLICATION_NAME}:socketio", :redis => redis_connection)
$redis_cache = Redis::Namespace.new("#{APPLICATION_NAME}:cache", :redis => redis_connection)

# redefine the procline methods to include APPLICATION_NAME so that `ps aux` will indicate the app.
# on servers with multiple apps, it can be difficult to identify which workers belong to which apps
# example
# ps aux | grep resque
#    johns    20188 24.5  0.5 250040 74344 pts/14   SN   15:22   0:05 resque-1.25.2: [10K] Waiting for *
module Resque
  class Worker
     def procline(string)
        $0 = "resque-#{Resque::Version}: [#{APPLICATION_NAME}] #{string}" 
        log! $0
      end
  end

  module Scheduler
    class << self
      def build_procline(string)
        "#{internal_name}#{app_str}#{env_str}: [#{APPLICATION_NAME}] #{string}" 
      end
    end
  end
end

module RedisExtensions
  def publish(channel, message)
    begin
      super
    rescue Redis::CannotConnectError
      Rails.logger.warn("REDIS CONNECTION FAILURE: Cannot connect to Redis. Need a good way of notifying devs without emailing every single instance, cause that could get crazy, fast.")
    rescue SocketError
      Rails.logger.warn("getaddrinfo: nodename nor servname provided, or not known")
    rescue Exception => e
      raise e
    end
  end
end

class Redis
  prepend RedisExtensions
end