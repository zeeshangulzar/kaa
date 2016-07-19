class HESRescueBadRequest
  def initialize(app)
    @app = app
  end
  def call(env)
    begin
      return @app.call(env)
    rescue MultiJson::ParseError => e
      error_output = "There was a problem in the JSON you submitted: #{e}"
      return [
        422,
        {"Content-Type" => "application/json" },
        [{:error => error_output}.to_json]
      ]
    end
  end
end