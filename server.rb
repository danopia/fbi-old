require File.join(File.dirname(__FILE__), 'common', 'connection')
require File.join(File.dirname(__FILE__), 'common', 'tinyurl')

module FBI
class Server
  attr_accessor :clients, :channels, :config

  def initialize config={}
    @config = config
    @clients = []
    @components = {}
    
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
    if @components.has_key? user.downcase
      false
    else
      @components[user.downcase] = client
      true
    end
  end
end

class Channel
  attr_accessor :name, :clients

  def initialize name, clients=[]
    @name = name
    @clients = clients
  end
  
  def << client
    send_to_all 'subscribe', 'origin' => client.username, 'target' => @name if client.authed?
    @clients << client
  end
  
  def delete client
    @clients.delete client
    send_to_all 'unsubscribe', 'origin' => client.username, 'target' => @name if client.authed?
  end

  def for_each &blck
    @clients.each {|conn| blck.call conn }
  end
  
  def send_to_all action, data
    @clients.each {|client| client.send_object action, data }
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
    if authed?
    elsif @server.auth self, data['user'], data['secret']
      @username = data['user']
      @secret = data['secret']
      puts "#{@ip}:#{@port} authed as #{@username}:#{@secret}"
      data.delete 'secret'
      send_object 'auth', data
    else
      puts "Invalid credentials from #{@ip}:#{@port}"
    end
  end

  def on_subscriptions data
    send_object 'subscriptions', :channels => @channels.map {|chan| chan.name }
  end

  def on_components data
    send_object 'components', :components => @server.components.keys
  end
  
  def on_channels data
    send_object 'channels', :channels => @server.channels.keys
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

  def on_unsubscribe data
    left = []
    
    data['channels'].uniq.each do |name|
      channel = @server.channels[name.downcase]
      if @channels.include? channel
        left << channel
        channel.delete self
      end
    end
      
    @channels -= new
    puts "#{@username} unsubscribed from #{left.join ', '}"
    
    data['channels'] = left
    send_object 'unsubscribe', data
  end

  def on_publish data
    FBI.shorten_urls_if_present data['data']

    puts "#{@username} to #{data['target']}: #{data['data'].to_json}"
    data['origin'] = @username

    if data['target'][0,1] == '#'
      @server.channels[data['target'].downcase].send_to_all 'publish', data
    else
      target = @server.components[data['target'].downcase]
      target && target.send_object('publish', data)
    end
  end
  
  def on_disconnect data
    send_object 'disconnect', {}
  end
  
  def unbind
    super
    @channels.each_value {|chan| chan.delete self }
    @server.components.delete @username.downcase if authed?
    @server.clients.delete self
  end
end
end

EM.run do
  server = FBI::Server.new
  server.serve
  puts "Server started"
end
