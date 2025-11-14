require 'bundler/setup'
Bundler.require(:default, ENV['RACK_ENV'] || :development)

require 'active_record'
require 'yaml'
require 'erb'
require 'dotenv/load'

# Load database configuration
db_config_file = File.expand_path('../database.yml', __FILE__)
db_config = YAML.safe_load(ERB.new(File.read(db_config_file)).result, aliases: true)

# Establish database connection
env = ENV['RACK_ENV'] || 'development'
ActiveRecord::Base.establish_connection(db_config[env])

# Load models
require_relative '../app/infrastructure/persistence/factura_model'

# Load domain, application and infrastructure layers
Dir[File.expand_path('../app/**/*.rb', __dir__)].each { |file| require file }
