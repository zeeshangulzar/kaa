namespace :db do 

  desc "load fbskeleton schema"
  task :seed_fbskeleton do
    db_conf = YAML.load_file("#{Rails.root}/config/database.yml")["development"]
    `mysql -u #{db_conf['username']} --password=#{db_conf['password']} -h #{db_conf['host']} -e 'CREATE DATABASE IF NOT EXISTS fbskeleton;'`
    `mysql -u #{db_conf['username']} --password=#{db_conf['password']} --database=fbskeleton -h #{db_conf['host']} < db/fbskeleton_schema.sql`
  end

  desc "load central recipes database"
  task :seed_recipes do
    puts 'Create Recipes'
    db_conf = YAML.load_file("#{Rails.root}/config/database.yml")["development"]

    `mysql -u #{db_conf['username']} --password=#{db_conf['password']} -h #{db_conf['host']} -e 'CREATE DATABASE IF NOT EXISTS central;'`
    `mysql -u #{db_conf['username']} --password=#{db_conf['password']} --database=central -h #{db_conf['host']} < db/central_recipes.sql`

  end

end