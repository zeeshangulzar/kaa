source 'http://dev:dev@gems.staging.hesapps.com'
source 'http://gems.github.com'
source 'http://rubygems.org/'

gem 'rails', '3.2.19'
gem 'rake', '10.3.2'

gem 'mysql2', '0.3.16'
gem 'rmagick', '~> 2.13'

gem 'rack-cors', :require => 'rack/cors'

gem 'json'

gem 'bcrypt-ruby', '3.0.1'
gem 'i18n', '0.6.11'

# HES Gems
gem "hes-authorization"
#gem "hes-cloud-storage", '1.0.10'
gem "carrierwave", '0.8.0'
gem "rest-client", '1.6.7'
gem "mime-types", '1.25.1'
gem "hes-sequencer"
gem "hes-events"
gem "redis", :group => [:development, :production]
gem 'oj'

gem "bluecloth", '2.2.0'
#gem 'yajl-ruby', :require => "yajl"
gem "resque", "1.25.2", :require => "resque/server"
gem "hes-resque-multi-job-forks"

#gem "hes-fitbit","1.0.21"
gem "hes-fitbit","2.0.5"
gem "hes-jawbone","1.0.7"

group :test do
  gem 'hes_route_docs'
end

group :production do
  gem 'exception_notification', "3.0.1"
end

gem 'memcache-client'
gem 'fastercsv'

gem 'newrelic_rpm'

gem 'htmlentities', "4.3.0"
