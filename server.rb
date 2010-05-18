require File.join(File.dirname(__FILE__), 'common', 'connection')
require File.join(File.dirname(__FILE__), 'common', 'tinyurl')

module FBI
class Server
  attr_accessor :clients, :channels, :components, :config, :next_uid

  def initialize config={}
    @config = config
    @clients = []
    @components = {}
    @next_uid = 1
    
    @channels = Hash.new do |hash, key|
      hash[key] = Channel.new key
    end
  end
  
  def serve
    @config['binds'].each do |bind|
      EventMachine::start_server bind['host'], bind['port'].to_i, ComponentConnection, self
    end
  end
  
  def start_loop
    EventMachine::run { serve }
  end

  def auth client, account, secret
    if @components.has_key? account.downcase
      false
    else
      @components[account.downcase] = client
      true
    end
  end
  
  def next_uid!
    (@next_uid += 1) - 1
  end
  
  def endpoint
    '$' + @config['hostname']
  end
end

class Channel
  attr_accessor :name, :components

  def initialize name, components=[]
    @name = name
    @components = components
  end
  
  def << client
    send_to_all 'subscribe', client.name, @name.join(','), 'channels' => [@name] # if client.authed?
    @clients << client
  end
  
  def delete client
    @clients.delete client
    send_to_all 'unsubscribe', 'origin' => client.username, 'channels' => [@name] # if client.authed?
  end

  def for_each &blck
    @clients.each {|conn| blck.call conn }
  end
  
  def send_to_all *args
    @clients.each {|client| client.send_object *args }
  end
  
  def size; @components.size; end
  
  def to_s; @name; end
  def endpoint; @name; end
end

class ComponentConnection < Connection
  attr_accessor :channels, :server, :uid

  def initialize server
    super()
    
    @uid = server.next_uid!
    @channels = []
    @server = server
    @server.clients << self
    
    send_object 'welcome', @server.endpoint, endpoint,
      :title => @server.config['label']
      :version => '0.1',
      :software => {:name => 'Official Ruby Router Implementation',
                    :version => '0.0.1',
                    :website => 'http://github.com/danopia/fbi/blob/master/server.rb'},
      :public => true,
      :runningSince => Time.now, # TODO: Make that the real time
    }
  end

  def receive_object action, *args
    if respond_to? "on_#{action}"
      __send__ "on_#{action}", *args
    else
      puts "Recieved unknown packet #{action}"
    end
  end
  
  def endpoint
    if @name
      @name
    else
      "~#{@uid}"
    end
  end
  
  def authed?
    @account && @secret
  end

  def on_auth origin, target, payload
    if authed?
    elsif @server.auth self, payload['account'], payload['secret']
      @name = payload['user']
      @username = payload['account']
      @secret = payload['secret']
      puts "#{@ip}:#{@port} authed as #{@username}:#{@secret}"
      #data.delete 'secret'
      send_object 'auth', endpoint, endpoint, payload
    else
      puts "Invalid credentials from #{@ip}:#{@port} for #{payload['account']}"
    end
  end

  #~ def on_subscriptions origin, target, payload
    #~ send_object 'subscriptions', :channels => @channels.map {|chan| chan.name }
  #~ end

  def on_components origin, target, payload
    send_object 'components', @server.endpoint, endpoint, :components => @server.components.keys
  end
  
  def on_channels origin, target, payload
    hash = @server.channels.map{|chan| [chan.name, chan.size] }.flatten
    send_object 'channels', @server.endpoint, endpoint, :channels => Hash[*hash]
  end

  def on_subscribe origin, target, payload
    new = []
    
    payload['channels'].uniq.each do |name|
      channel = @server.channels[name.downcase]
      channel.name = name if channel.clients.size == 0
      
      unless @channels.include? channel
        new << channel
        channel << self
      end
    end
      
    @channels |= new
    puts "#{@username} subscribed to #{new.join ', '}"
    
    send_object 'subscribe', endpoint, new.join(','), :channels => new
  end

  def on_unsubscribe origin, target, payload
    left = []
    
    payload['channels'].uniq.each do |name|
      channel = @server.channels[name.downcase]
      if @channels.include? channel
        left << channel
        channel.delete self
      end
    end
      
    @channels -= left
    puts "#{@username} unsubscribed from #{left.join ', '}"
    
    send_object 'unsubscribe', endpoint, left.join(','), :channels => left
  end

  def on_publish origin, target, payload
    # FBI.shorten_urls_if_present payload['data']

    puts "#{@username} to #{target}: #{payload.to_json}"

    if target[0,1] == '#'
      @server.channels[target.downcase].send_to_all 'publish', endpoint, target, payload
    else
      target = @server.components[target.downcase]
      target && target.send_object('publish', endpoint, target, payload)
    end
  end
  
  # TODO: MORE PACKETS NEEDED:
  # subscribers, setinfo, info, ping, pong, introspect
  
  def on_disconnect origin, target, payload
    send_object 'disconnect', endpoint, endpoint # TODO: Route to channels
    close_connection_after_waiting
  end
  
  def unbind
    super
    @channels.each {|chan| chan.delete self }
    @server.components.delete @username.downcase if authed?
    @server.clients.delete self
  end
end
end

config_path = File.join(File.dirname(__FILE__), 'server.yaml')
config_path << '.dist' unless File.exist? config_path

require 'yaml'
config = YAML.load File.read(config_path)

server = FBI::Server.new config

EM.next_tick do
  server.serve
  puts "Server started"
end

EventMachine.run {} if $0 == __FILE__
