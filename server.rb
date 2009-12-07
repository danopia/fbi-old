require File.join(File.dirname(__FILE__), 'common', 'connection')

require 'open-uri'

def shorten_url url
	open('http://is.gd/api.php?longurl=' + url).read
end

module FBI
class Server < Connection
	def self.serve *args
  	EventMachine::start_server "127.0.0.1", 5348, self, *args
	end
	def self.start_loop *args
		EventMachine::run { self.serve *args }
	end
	
	attr_accessor :channels
	
  def startup
    @channels = []
  end
  
  def receive_object action, data
		case action
			when 'auth'
				@username = data['user']
				@secret = data['secret']
				puts "#{@ip}:#{@port} authed as #{@username}:#{@secret}"
				send_object 'auth', data
    
  		when 'subscribe'
				@channels |= data['channels']
				puts "#{@username} subscribed to #{data['channels'].join ', '}"
				send_object 'subscribe', data
    
			when 'private'
				if data['data'].has_key? 'url'
					data['data']['shorturl'] = shorten_url data['data']['url']
				end
				
				puts "#{@username} for #{data['to']} (#{data['id']}: #{data['data'].to_json}"
				data['from'] = @username
				INSTANCES.find {|conn| conn.username == data['to']}.send_object 'private', data
    
			when 'publish'
				if data['data'].has_key? 'url'
					data['data']['shorturl'] = shorten_url data['data']['url']
				end
				
				puts "#{@username} to #{data['channel']}: #{data['data'].to_json}"
				data['from'] = @username
				
				INSTANCES.each do |conn|
					conn.send_object 'publish', data if conn.channels.include? data['channel']
				end
		end
  end
end
end

EM.run do
  FBI::Server.serve
  puts "server started"
end
