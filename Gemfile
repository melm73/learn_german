source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.3'

gem 'rails'
gem 'pg'
gem 'puma'
gem 'webpacker'
gem 'bcrypt'

gem 'sass-rails'
gem 'turbolinks'
gem 'bootsnap', '>= 1.4.2', require: false

group :development, :test do
  gem 'rspec-rails'
  gem 'sqlite3'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'web-console'
  gem 'listen'
  gem 'spring'
  gem 'spring-watcher-listen'
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end
