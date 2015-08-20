$redis = Redis.new(:host => 'localhost', :port => 6379);
Resque.redis.namespace = APPLICATION_NAME
