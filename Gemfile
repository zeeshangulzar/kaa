source 'http://dev:dev@gems.staging.hesapps.com'
source 'http://gems.github.com'
source 'http://rubygems.org/'

gem 'rails', '3.2.22.2'
gem 'rake', '10.3.2'
gem 'test-unit', '~> 3.0'
gem 'mysql2', '0.3.18'
gem 'rmagick', '~> 2.13'
gem 'rack-cors', :require => 'rack/cors'
gem 'json'
gem 'bcrypt-ruby', '3.0.1'
gem 'i18n', '0.6.11'
gem "carrierwave", '0.8.0'
gem "rest-client", '1.6.7'
gem "mime-types", '1.25.1'
gem "redis", :group => [:development, :production]
gem 'oj'
gem "bluecloth", '2.2.0'
gem "resque", "1.25.2", :require => "resque/server"
gem 'memcache-client'
gem 'fastercsv'
gem 'newrelic_rpm'
gem 'htmlentities', "4.3.0"
gem 'dalli'

# HES Gems
gem "hes-authorization"
gem "hes-resque-multi-job-forks", "0.4.3.1"
gem 'hes-resque-scheduler', '4.0.0'
gem "hes-fitbit","2.1.6"
gem "hes-jawbone","1.0.8"

group :development do
  gem 'derailed_benchmarks'
end

group :production do
  gem 'exception_notification', "3.0.1"
end

gem 'american_date'

gem 'charlock_holmes'
# installing charlock..
# on linux:
# sudo yum install libicu-devel
# gem install charlock_holmes
# on mac:
# brew install icu4c
