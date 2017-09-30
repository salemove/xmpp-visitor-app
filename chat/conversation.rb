require 'xmpp4r'
require 'xmpp4r/muc/helper/simplemucclient'
require 'tty-prompt'

module Chat
  class Conversation
    INVITATION = 'Hello, I would like to have your assistance'.freeze
    NICK = 'Visitor'.freeze

    def initialize(jabber_client, visitor_jid, operator_jid)
      @jabber_client = jabber_client
      @visitor_jid = visitor_jid
      @operator_jid = operator_jid
      @muc_client = build_muc_client
    end

    def start
      join_room
      invite_operator unless operator_present?
      begin_conversation
    end

    private

    def build_muc_client
      main_thread = Thread.current
      client = Jabber::MUC::SimpleMUCClient.new(@jabber_client)
      client.on_join do |time, nick|
        puts "** #{nick} has joined!\r"
      end

      client.on_leave do |time, nick|
        puts "** #{nick} has left!\r"
        @muc_client.exit
        main_thread.wakeup
      end

      client.on_message do |time, nick, text|
        puts "#{nick}: #{text}\r"
      end

      client.on_room_message do |time, text|
        puts "** #{text}\r"
      end

      client.on_subject do |time, nick, text|
        puts "** (#{nick}) #{text}\r"
      end

      client
    end

    def join_room
      @muc_client.join("#{room_jid}/#{@visitor_jid.node}", nil, history: false)
    end

    def room_jid
      "#{@visitor_jid.node}-engagement@conference.#{@visitor_jid.domain}"
    end

    def operator_present?
      @muc_client.roster.size > 1
    end

    def invite_operator
      # constructing invitation message
      # see https://xmpp.org/extensions/xep-0045.html#invite-mediated
      message = Jabber::Message.new
      message.from = @visitor_jid.to_s
      message.to = room_jid
      x = message.add(Jabber::MUC::XMUCUser.new)
      x.add Jabber::MUC::XMUCUserInvite.new(@operator_jid.to_s, INVITATION)
      @jabber_client.send(message)
    end

    def begin_conversation
      main_thread = Thread.current

      Thread.start do
        prompt = TTY::Prompt.new

        begin
          loop do
            message = prompt.ask('> ')
            @muc_client.say(message)
          end
        rescue TTY::Reader::InputInterrupt
          @muc_client.exit
          main_thread.wakeup
        end
      end

      Thread.stop
      @jabber_client.close
    end
  end
end
