require 'json'
require 'sinatra'

get '/show/:filename' do |filename|
  file = File.open(File.dirname(__FILE__) + '/../' + filename)
  map = JSON.parse(file.read)
  haml :show, :locals => {:map => map}
end
