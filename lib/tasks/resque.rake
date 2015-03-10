namespace :resque do
  task :restart do
    pids = []
    f = File.open('resque.pid') if File.exists?('resque.pid')
    if f
      f.each_line{|line|
        pids.push(line)
      }
    end
    pids.each{|pid|
      puts "Attempting to gracefully murder resque process: #{pid}"
      if !system("kill -3 #{pid}")
        puts "Process doesnt exist"
      end
    }
    puts "Dropping resque.pid so resque can make a new one without hassle..."
    File.delete('resque.pid') if File.exists?('resque.pid')
    puts "Firing up resque..."
    system("(cd #{Dir.pwd} && nohup nice -5 HES_SECURITY_DISABLED=true bundle exec rake environment resque:work RAILS_ENV=production QUEUE=* PIDFILE=./resque.pid >> 'log/resque.log' 2>&1 &) && sleep 1")
    puts "Should be up."
  end
end
