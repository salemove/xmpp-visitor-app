require 'sinatra'
require 'rom-repository'
require 'xmpp4r'

JABBER_DOMAIN = '10.200.0.138'.freeze
API_JID = "api@#{JABBER_DOMAIN}".freeze

rom = ROM.container(:sql, 'postgres://localhost/tcobr') do |conf|
end

class Visitor
  attr_reader :id, :password

  def initialize(attributes)
    @id, @password = attributes.values_at(:id, :password)
  end

  def serialize
    {
      id: @id,
      jid: jid,
      password: @password
    }
  end

  def jid
    "#{@id}@#{JABBER_DOMAIN}"
  end
end

class VisitorRepo < ROM::Repository[:visitors]
  commands :create

  def all
    visitors.as(Visitor).to_a
  end

  def get(id)
    visitors.as(Visitor).where(id: id).one!
  end

  def delete(id)
    visitors.as(Visitor).where(id: id).delete
  end

  def delete_all
    visitors.as(Visitor).delete
  end
end
visitor_repo = VisitorRepo.new(rom)

get '/visitors' do
  visitor_repo.all.map(&:serialize).to_json
end

post '/visitors' do
  v = visitor_repo.create(password: params.fetch(:password))
  register(v.fetch(:id), params.fetch(:password))
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
