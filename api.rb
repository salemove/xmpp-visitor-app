require 'sinatra'
require 'rom-repository'

JABBER_DOMAIN = '10.200.0.138'.freeze

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
      jid: "#{@id}@#{JABBER_DOMAIN}",
      password: @password
    }
  end
end

class VisitorRepo < ROM::Repository[:visitors]
  commands :create

  def all
    visitors.as(Visitor).to_a
  end

  def delete(id)
    visitors.where(id: id).delete
  end
end
visitor_repo = VisitorRepo.new(rom)

get '/visitors' do
  visitor_repo.all.map(&:serialize).to_json
end

post '/visitors' do
  visitor_repo.create(password: params[:password]).to_h
end

delete '/visitors/:id' do |id|
  visitor_repo.delete(id)
end
