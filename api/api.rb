require 'sinatra'
require 'rom-repository'
require 'xmpp4r'

require_relative 'visitors'
require_relative 'requests'

JABBER_DOMAIN = '10.200.0.138'.freeze
API_JID = "api@#{JABBER_DOMAIN}".freeze

rom = ROM.container(:sql, 'postgres://localhost/tcobr') do |conf|
end
visitor_repo = VisitorRepo.new(rom)
requests_repo = RequestRepo.new(rom)

helpers do
  def unauthorized!
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, {message: "Not authorized"}.to_json
  end
end

before do
  response.headers["Access-Control-Allow-Origin"] = "*"
  response.headers["Access-Control-Allow-Credentials"] = "true"
  response.headers["Access-Control-Allow-Methods"] = "GET, POST"
  response.headers["Access-Control-Allow-Headers"] = "Origin, X-Requested-With, Content-Type, Accept, Authorization"
end

options '/*' do
  status 200
end

get '/visitors' do
  visitor_repo.all.map(&:serialize).to_json
end

post '/visitors' do
  v = visitor_repo.create(password: params.fetch(:password))
  register(v.fetch(:id), params.fetch(:password))
  {id: v.fetch(:id)}.to_json
end

delete '/visitors/:id' do |id|
  visitor = visitor_repo.get(id)
  unregister(visitor)
  visitor_repo.delete(id)
end

delete '/visitors' do
  visitor_repo.all.each(&method(:unregister))
  visitor_repo.delete_all
end

get '/cat_pics' do
  auth = Rack::Auth::Basic::Request.new(request.env)
  visitor = auth.provided? && auth.basic? && auth.credentials && visitor_repo.get(auth.credentials[0])
  unauthorized! unless visitor && (visitor.password == auth.credentials[1] || auth.credentials[1] == 'super_secret_operator_pass')

  requests_repo.for_visitor(visitor.id).map(&:to_h).to_json
end

post '/cat_pics' do
  auth = Rack::Auth::Basic::Request.new(request.env)
  visitor = auth.provided? && auth.basic? && auth.credentials && visitor_repo.get(auth.credentials[0])
  unauthorized! unless visitor && (visitor.password == auth.credentials[1] || auth.credentials[1] == 'super_secret_operator_pass')

  url = params.fetch(:url)
  valid = valid_cat_pic?(url)
  r = requests_repo.create({
    visitor_id: visitor.id,
    cat_pic_url: url,
    valid: valid
  }).to_h
  if valid
    r.to_json
  else
    halt 422, r.merge({
      message: "Cat pictures have to be cute!",
      debug_message: "./cobrowse.sh #{visitor.jid} #{visitor.password} alexei@#{JABBER_DOMAIN}"
    }).to_json
  end
end

def register(id, password)
  jid = "#{id}@#{JABBER_DOMAIN}"
  cl = Jabber::Client.new(Jabber::JID.new(jid))
  cl.connect
  begin
    cl.register(password)
  ensure
    cl.close
  end
end

def unregister(visitor)
  cl = Jabber::Client.new(Jabber::JID.new(visitor.jid))
  cl.connect
  begin
    cl.auth(visitor.password)
    cl.remove_registration
  ensure
    cl.close
  end
end

def valid_cat_pic?(url)
  !!(url =~ /cute/)
end
