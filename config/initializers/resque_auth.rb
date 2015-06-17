Resque::Server.use(Rack::Auth::Basic) do |userName,password| 
	userName = "admin"
	password == "BL33bm29?TpB"
end