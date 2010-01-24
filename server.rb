require File.join(File.dirname(__FILE__), 'common', 'connection')
require File.join(File.dirname(__FILE__), 'common', 'tinyurl')

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
			if respond_to? "on_#{action}"
				__send__ "on_#{action}", data
			else
				puts "Recieved unknown packet #{action}"
			end
		end
		
		def on_auth data
			@username = data['user']
			@secret = data['secret']
			puts "#{@ip}:#{@port} authed as #{@username}:#{@secret}"
			send_object 'auth', data
		end
		
		def on_subscribe data
			@channels |= data['channels']
			puts "#{@username} subscribed to #{data['channels'].join ', '}"
			send_object 'subscribe', data
		end

		def on_private data
			shorten_url_if_present data['data']

			puts "#{@username} for #{data['to']} (#{data['id']}): #{data['data'].to_json}"
			data['from'] = @username
			
			for_client data['to'] do |client|
				client.send_object 'private', data
			end
		end

		def on_publish data
			shorten_url_if_present data['data']

			puts "#{@username} to #{data['channel']}: #{data['data'].to_json}"
			data['from'] = @username

			for_subscribers_of data['channel'] do |client|
				client.send_object 'publish', data
			end
    end
		
		
		def for_client name, &blck
			client = INSTANCES.find {|conn| conn.username == name}
			blck.call client if client
			client
		end
		def for_subscribers_of channel, &blck
			INSTANCES.each do |conn|
				blck.call conn if conn.channels.include? channel
			end
		end
  end
end

EM.run do
  FBI::Server.serve
  puts "Server started"
end
