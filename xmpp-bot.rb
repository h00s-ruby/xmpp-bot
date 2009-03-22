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

  def add_command(command, syntax, description, &callback)
    @commands[command] = {
      'syntax' => syntax,
      'description' => description,
      'callback' => callback
    }
  end

  def run_command(command, params)
    return @commands[command]['callback'].call(params)
  end

  private
  def parse_message(message)
    sender = message.from
    if @config['operators'].include?(sender.to_s.sub(/\/.+$/, ''))
      command = message.body.to_s.split(' ')[0]
      params = message.body.to_s.split(' ')[1..-1]
      if @commands.has_key?(command)
        response = run_command(command, params)
        respond(sender, response)
      end
    end
  end

end
