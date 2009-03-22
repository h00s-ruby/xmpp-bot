require 'xmpp4r'
include Jabber

class XMPPBot

  def initialize(config)
    @config = config
    @commands = {}
    @jabber = Client.new(JID::new(@config['JID'] + '/' + @config['resource']))
    @jabber.on_exception { sleep 5; connect() }
  end

  def connect
    @jabber.connect
    @jabber.auth(@config['password'])
    @jabber.send(Presence.new.set_type(:available))
  end

  def disconnect
    @jabber.close
  end

  def listen
    @jabber.add_message_callback do |message|
      parse_message(message)
    end
  end

  def respond(to, message)
    @jabber.send(Message::new(to, message).set_type(:chat))
  end

  private
  def parse_message(message)
    if @config['operators'].include?(message.from.to_s.sub(/\/.+$/, ''))
      parse_command(message.from, message.body)
    end
  end

  def parse_command(sender, command)
    
  end

end