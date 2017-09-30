JABBER_DOMAIN = '10.200.0.138'.freeze

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
