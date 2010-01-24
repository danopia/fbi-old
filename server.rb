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
			if data['data'].has_key? 'url'
				data['data']['shorturl'] = shorten_url data['data']['url']
			end

			puts "#{@username} for #{data['to']} (#{data['id']}): #{data['data'].to_json}"
			data['from'] = @username
			INSTANCES.find {|conn| conn.username == data['to']}.send_object 'private', data
		end

		def on_publish data
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

EM.run do
  FBI::Server.serve
  puts "Server started"
end
