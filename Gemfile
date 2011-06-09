source 'http://rubygems.org'

gem 'rails', '3.1.0.rc3'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

gem 'sqlite3', :group => :development

# Asset template engines
gem 'slim'
gem 'sass'
#gem 'coffee-script'
gem 'uglifier'

gem 'jquery-rails'

# Use thin as the web server
gem 'thin'


# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

gem 'nokogiri'
gem 'mechanize'

# Rake 0.9 breaks Rails: http://twitter.com/#!/dhh/status/71966528744071169
gem 'rake', '0.8.7'

group :test do
  # Pretty printed test output
  gem 'turn', :require => false
end

group :production do
  # Heroku needs the following for Rails 3.1 sprockets to work: http://www.quickleft.com/blog/rails-31-sprockets-and-heroku
  gem 'therubyracer-heroku', '0.8.1.pre3'
  
  # Heroku also needs the postgres gem: http://devcenter.heroku.com/articles/bundler
  gem 'pg'
end