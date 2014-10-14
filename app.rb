require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/cross_origin'
require 'sinatra/jsonp'
require './sinatra_ssl'
require 'json'
require 'net/http'
require 'net/https'
require 'open-uri'


class RedirectFollower
  class TooManyRedirects < StandardError; end

  attr_accessor :url, :body, :redirect_limit, :response

  def initialize(url, api_port, limit = 10)
    @url, @redirect_limit = url, limit
    @api_port = api_port
  end

  def resolve
    raise TooManyRedirects if redirect_limit < 0

    uri = URI.parse URI.encode(url)
    the_request = Net::HTTP::Get.new uri

    self.response = Net::HTTP.start(uri.host, @api_port) { |http|
      http.request(the_request)
    }

    if response.kind_of?(Net::HTTPRedirection)
      self.url = redirect_url
      self.redirect_limit -= 1

      resolve
    end

    self.body = response.body
    self
  end

  def redirect_url
    if response['location'].nil?
      response.body.match(/<a href=\"([^>]+)\">/i)[1]
    else
      response['location']
    end
  end
end


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
    set :api_url, 'http://**.**.**.**'
    set :api_port, 80
    register Sinatra::Reloader
  end

  configure :production do
    set :api_url, 'http://api.ayouken.com'
    set :api_port, 80
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

    def execute_query(url)
      puts url
      # res = RedirectFollower.new(url, settings.api_port).resolve
      # body = JSON.parse res.body
      # json_status body['status'], body['data']

      content_type :json
      body = open(url
        # , proxy_http_basic_authentication: ['', '', '']
      ).read
      jsonp JSON.parse body
    end
  end

  get '/:command' do
    url = "#{settings.api_url}:#{settings.api_port}/#{params[:command]}"
    execute_query url
  end

  get '/:command/:param' do
    url = "#{settings.api_url}:#{settings.api_port}/#{params[:command]}/#{params[:param]}"
    execute_query url
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
