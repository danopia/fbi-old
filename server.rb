#$stdout.sync = true

require 'rubygems'
require 'eventmachine'
require 'socket'
require 'open-uri'
require 'json'

def shorten_url url
	open('http://is.gd/api.php?longurl=' + url).read
end

module FBI
class Server < EventMachine::Connection
	attr_accessor :subscriptions, :sender, :port, :ip
	INSTANCES = []
	
  def initialize
    @port, @ip = Socket.unpack_sockaddr_in get_peername
    puts "connection from #{@ip}:#{@port}"
    @buffer = ''
    @sender = false
    @subscriptions = []
    
    INSTANCES << self
  end

  def receive_data data
    @buffer += data
    while @buffer.include? "\n"
    	got_line @buffer.slice!(0, @buffer.index("\n")+1).chomp
    end
  end
  
  def got_line line
		data = JSON.parse line
		if data.has_key? 'auth'
			@sender = data['user']
    	puts "#{@ip}:#{@port} asked to be a sender, as #{@sender}"
    
  	elsif data.has_key? 'subscribe'
			@subscriptions |= data['feeds']
    	puts "#{@ip}:#{@port} subscribed to #{data['feeds'].join ', '}"
    
  	elsif @sender
  	
  		if data['data'].has_key? 'url'
				data['data']['shorturl'] = shorten_url data['data']['url']
			end
			
  		json = data['data'].to_json
			puts "#{@sender} to #{data['channel']}: #{json}"
  		json = {'channel' => data['channel'], 'data' => data['data']}.to_json
			
			INSTANCES.each do |conn|
				conn.send_data "#{json}\n" if conn.subscriptions.include? data['channel']
			end
		end
  end
  
  def unbind
  	puts "connection closed from #{@ip}:#{@port}"
  	INSTANCES.delete self
  end
end # class
end # module

EM.run do
  EM.start_server "127.0.0.1", 5348, FBI::Server
  puts "server started"
end
