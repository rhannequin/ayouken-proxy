require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/cross_origin'
require 'sinatra/jsonp'
require './sinatra_ssl'
require 'json'
require 'net/http'
require 'net/https'

class AyoukenProxy < Sinatra::Base
  register Sinatra::CrossOrigin

  set :method_override, true
  set :environments, %w(production development test)
  set :environment, (ENV['RACK_ENV'] || :development).to_sym
  set :ssl_certificate, 'server.crt'
  set :ssl_key, 'server.key'
  set :allow_origin, :any
  set :expose_headers, ['Content-Type']

  configure do
    enable :logging
    enable :cross_origin
  end

  configure :development, :test do
    set :logging, Logger::DEBUG
    set :api_url, 'http//localhost:7000'
    register Sinatra::Reloader
  end

  configure :production do
    set :api_url, 'http//api.ayouken.com'
    set :logging, Logger::INFO
  end

  def self.put_or_post(*a, &b)
    put *a, &b
    post *a, &b
  end

  helpers Sinatra::Jsonp
  helpers do
    def json_status(code, data)
      content_type :json
      status code
      jsonp status: code, data: data
    end
  end

  get '/:command' do
    url = "#{settings.api_ur}/#{params['command']}"
    # http = Net::HTTP::Proxy proxy_host, proxy_port, proxy_user, proxy_password
    http = Net::HTTP
    result = JSON.parse http.get_response(URI.parse(url)).body
    json_status result['status'], result['data']
  end


  # Default handlers

  get '*' do
    json_status 404, 'Not found'
  end

  put_or_post '*' do
    json_status 404, 'Not found'
  end

  delete '*' do
    json_status 404, 'Not found'
  end

  not_found do
    json_status 404, 'Not found'
  end

  error do
    json_status 500, env['sinatra.error'].message
  end

end
