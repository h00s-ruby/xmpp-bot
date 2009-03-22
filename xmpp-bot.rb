require 'xmpp4r'
include Jabber

class XMPPBot

  def initialize(config)
    @config = config
    @commands = {}
    @jabber = Client.new(JID::new(@config['JID'] + '/' + @config['resource']))
    @jabber.on_exception { sleep 5; connect() }
    add_default_commands
  end

  def connect
    @jabber.connect
    @jabber.auth(@config['password'])
    keep_alive
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
    @jabber.send(Message.new(to, message).set_type(:chat))
  end

  def add_command(command, syntax, description, public = false, &callback)
    @commands[command] = {
      'syntax' => syntax,
      'description' => description,
      'callback' => callback,
      'public' => public
    }
  end

  def add_default_commands
    add_command('help', 'help', 'show all bot commands', true) do |params|
      message = "Available commands:"
      @commands.sort.each do |command, command_info|
        message += "\n#{command_info['syntax']} - #{command_info['description']}"
      end
      message
    end

    add_command('addoperator', 'addoperator <jid> <password>', 'add user with <jid> to operators list') do |params|
      message = "Available commands:"
      @commands.sort.each do |command, command_info|
        message += "\n#{command_info['syntax']} - #{command_info['description']}"
      end
      message
    end
  end

  def run_command(command, params)
    return @commands[command]['callback'].call(params)
  end

  def keep_alive
    Thread.new do
      while true
        @jabber.send(Presence.new.set_type(:available))
        sleep(120)
      end
    end
  end

  private
  def parse_message(message)
    sender = message.from
    command = message.body.to_s.split(' ')[0]
    params = message.body.to_s.split(' ')[1..-1]
    if @commands.has_key?(command)
        begin
          if @config['operators'].include?(sender.to_s.sub(/\/.+$/, '')) or @commands[command]['public']
            response = run_command(command, params)
          else
            response = 'Sorry, this command is not public and you\'re not an operator'
          end
        rescue Exception => e
          response = "#{e} (#{e.class})!"
        ensure
          respond(sender, response.to_s)
        end
    end

    if @config['operators'].include?(sender.to_s.sub(/\/.+$/, ''))
      if @commands.has_key?(command)
      end
    end
  end

end
