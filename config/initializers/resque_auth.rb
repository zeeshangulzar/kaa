Resque::Server.use(Rack::Auth::Basic) do |userName,password| 
	userName = "admin"
	password == "WZfs5Mn9"
end