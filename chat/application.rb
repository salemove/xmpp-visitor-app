require 'xmpp4r'
require_relative './conversation'

module Chat
  class Application
    JABBER_HOST = '10.200.0.138'.freeze

    def initialize(jid, password, operator_jid)
      @visitor_jid = Jabber::JID.new(jid)
      @jabber_client = Jabber::Client.new(@visitor_jid)
      @operator_jid = Jabber::JID.new(operator_jid)
      @room_jid = "#{@visitor_jid.node}@conference.#{@visitor_jid.domain}"
      @conversation = Conversation.new(
        @jabber_client,
        @visitor_jid,
        Jabber::JID.new(operator_jid)
      )
      @password = password
    end

    def start(greetings)
      authenticate
      start_conversation(greetings)
    end

    private

    def authenticate
      @jabber_client.connect(@visitor_jid.domain)
      @jabber_client.auth(@password)
      @jabber_client.send(Jabber::Presence.new)
    end

    def start_conversation(greetings)
      Conversation.new(
        @jabber_client,
        @visitor_jid,
        @operator_jid
      ).start(greetings)
    end
  end
end
