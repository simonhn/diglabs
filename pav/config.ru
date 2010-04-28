#config.ru
## Passenger should set RACK_ENV for Sinatra
# This file goes in domain.com/config.ru
require 'rubygems'
gem 'sinatra', '=0.9.6'
require 'sinatra'
#require 'rack/cache'
require 'pav'

#use Rack::Cache,
#  :verbose     => true,
#  :metastore   => 'file:/var/cache/rack/meta',
#  :entitystore => 'file:/var/cache/rack/body'

use Rack::JSONP

set :environment,  :development
disable :run
enable :logging, :dump_errors, :raise_errors, :show_exceptions

run Sinatra::Application