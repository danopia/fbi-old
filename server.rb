require File.join(File.dirname(__FILE__), 'common', 'connection')
require File.join(File.dirname(__FILE__), 'common', 'tinyurl')

module FBI
class Server
  attr_accessor :clients, :channels, :config

  def initialize config={}
    @config = config
    @clients = []
    
    @channels = Hash.new do |hash, key|
      hash[key] = Channel.new key
    end
  end
  
  def serve
    EventMachine::start_server "0.0.0.0", 5348, ServerConnection, self
  end
  def start_loop
    EventMachine::run { serve }
  end

  def auth client, user, pass
    true
  end

  def for_client name, &blck
    client = @clients.find {|conn| conn.username == name}
    client && blck.call(client)
    client
  end
end

class Channel
  attr_accessor :name, :clients

  def initialize name, clients=[]
    @name = name
    @clients = clients
  end
  
  def << client
    @clients << client
  end
  def delete client
    @clients.delete client
  end

  def for_each &blck
    @clients.each {|conn| blck.call conn }
  end
  
  def to_s
    @name
  end
end

class ServerConnection < Connection
  attr_accessor :channels, :server

  def initialize server
    super()
    
    @channels = []
    @server = server
    @server.clients << self
  end

  def receive_object action, data
    if respond_to? "on_#{action}"
      __send__ "on_#{action}", data
    else
      puts "Recieved unknown packet #{action}"
    end
  end
  
  def authed?
    @username && @secret
  end

  def on_auth data
    if @server.auth self, data['user'], data['secret']
      @username = data['user']
      @secret = data['secret']
      puts "#{@ip}:#{@port} authed as #{@username}:#{@secret}"
      data.delete 'secret'
      send_object 'auth', data
    else
      puts "Invalid credentials from #{@ip}:#{@port}"
    end
  end

  def on_subscribe data
    new = []
    
    data['channels'].uniq.each do |name|
      channel = @server.channels[name.downcase]
      channel.name = name if channel.clients.size == 0
      
      unless @channels.include? channel
        new << channel
        channel << self
      end
    end
      
    @channels |= new
    puts "#{@username} subscribed to #{new.join ', '}"
    
    data['channels'] = new
    send_object 'subscribe', data
  end

  def on_publish data
    FBI.shorten_urls_if_present data['data']

    puts "#{@username} to #{data['target']}: #{data['data'].to_json}"
    data['origin'] = @username

    if data['target'][0,1] == '#'
      @server.channels[data['target'].downcase].for_each do |client|
        client.send_object 'publish', data
      end
    else
      @server.for_client data['target'] do |client|
        client.send_object 'private', data
      end
    end
  end
end
end

EM.run do
  server = FBI::Server.new
  server.serve
  puts "Server started"
end
