#!/usr/bin/env ruby

require 'active_record'
require 'yaml'
require 'erb'

# Load database configuration
db_config_file = File.expand_path('config/database.yml', __dir__)
db_config = YAML.safe_load(ERB.new(File.read(db_config_file)).result, aliases: true)

# Establish database connection
env = ENV['RACK_ENV'] || 'development'
ActiveRecord::Base.establish_connection(db_config[env])

# Run migrations
ActiveRecord::MigrationContext.new('db/migrate', ActiveRecord::SchemaMigration).migrate

puts "Migrations completed successfully!"
