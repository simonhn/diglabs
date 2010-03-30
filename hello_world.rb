# hello_world.rb
require 'rubygems'
require 'sinatra'

get '/' do
  "Hello world, it's #{Time.now} at the server!"
end
