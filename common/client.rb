require File.join(File.dirname(__FILE__), 'connection')

module FBI
	class Client < Connection
		@@on_auth = nil
		@@on_private = nil
		@@on_published = nil
		
		def self.on_auth &blck
			@@on_auth = blck
		end
		def self.on_published &blck
			@@on_published = blck
		end
		def self.on_private &blck
			@@on_private = blck
		end
		
		def self.connect *args
			EventMachine::connect "danopia.net", 5348, self, *args
		end
		def self.start_loop *args
			EventMachine::run { self.connect *args }
		end
		
		def self.private target, data
			@@instance.send_object 'private', {
				'to'		=> target,
				'data'	=> data
			}
		end
		def self.publish channel, data
			@@instance.send_object 'publish', {
				'channel'	=> channel,
				'data'		=> data
			}
		end
		
		def login
			send_object 'auth', {
				'user'		=> @username,
				'secret'	=> @secret
			}
		end
  
		def startup channels=[]
			subscribe_to channels if channels.any?
		end
		
		def subscribe_to channels
			send_object 'subscribe', {'channels' => channels}
		end
		
		def receive_object action, data
			case action
				when 'auth'
					puts "logged in"
					@@on_auth.call data if @@on_auth
				
				when 'private'
					puts "got private packet from #{data['from']}"
					@@on_private.call data['from'], data['data'] if @@on_private
			
				when 'publish'
					puts "got public packet from #{data['from']} via #{data['channel']}"
					@@on_published.call data['channel'], data['data'] if @@on_published
			end
		end
	end
end
