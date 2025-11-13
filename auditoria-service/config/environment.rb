require 'bundler/setup'
Bundler.require(:default, ENV['RACK_ENV'] || :development)

require 'mongo'
require 'dotenv/load'

# Load models and infrastructure
require_relative '../app/models/audit_event'
require_relative '../app/infrastructure/persistence/mongo_audit_repository'
