require 'json'
require 'sinatra'
require 'tilt/haml'

get '/show/:filename' do |filename|
  file = File.open(File.dirname(__FILE__) + '/../' + filename)
  map = JSON.parse(file.read)
  start = (params[:s] || 0).to_i
  per_page = (params[:p] || 100).to_i
  slice = map.to_a[start..(start + per_page)]
  haml :show, :locals => {slice: slice, start: start, per_page: per_page, :total => map.size}
end
