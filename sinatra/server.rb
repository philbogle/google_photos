require 'json'
require 'sinatra/base'
require 'sinatra/config_file'
require 'tilt/haml'

DIR = File.dirname(__FILE__)

class MyApp < Sinatra::Base

  register Sinatra::ConfigFile
  config_file DIR + '/config.yml'

  get '/show/:filename' do |filename|
    file = File.open(DIR + '/../' + filename)
    map = JSON.parse(file.read)
    start = (params[:s] || 0).to_i
    per_page = (params[:p] || 100).to_i
    slice = map.to_a[start..(start + per_page)]
    haml :show, :locals => {slice: slice, start: start, per_page: per_page, :total => map.size}
  end

  run! if __FILE__ == $0
end
