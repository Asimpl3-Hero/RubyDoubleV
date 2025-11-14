require 'bundler/setup'
Bundler.require(:default, ENV['RACK_ENV'] || :development)

require 'mongo'
require 'dotenv/load'
