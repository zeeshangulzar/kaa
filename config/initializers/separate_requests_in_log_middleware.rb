class SeparateRequestsInLogMiddleware
  def initialize(app, options = {})
    @log = Rails.logger.instance_variable_get(:@logger).instance_variable_get(:@log).instance_variable_get(:@logdev).instance_variable_get(:@dev)
    @log.sync = false
    @app = app
  end

  def call(env)
    @app.call(env)
  ensure
    @log.flush # Rails.logger.flush has no effect / is deprecated
  end
end

Go::Application.config.middleware.insert_before(Rails::Rack::Logger, SeparateRequestsInLogMiddleware)
