require File.join(File.dirname(__FILE__), 'drone')

module FBI
	class Client < Connection
		attr_reader :handlers, :drone, :subscriptions
		attr_accessor :name, :secret
		
		def initialize name, secret=nil
			@name = name
			@secret = secret
			@handlers = {}
			@subscriptions = []
		end
		
		def on event, &blck
			@handlers[event.to_sym] = blck
		end
		
		def connect args={}
			@drone = Drone.connect self, args
			subscribe_to @subscriptions if @subscriptions.any?
		end
		def start_loop *args
			@drone = Drone.start_loop self, args
		end
		
		def private target, data
			@drone.send_object 'private', {
				'to'		=> target,
				'data'	=> data
			}
		end
		def publish channel, data
			@drone.send_object 'publish', {
				'channel'	=> channel,
				'data'		=> data
			}
		end
		
		def login
			@drone.send_object 'auth', {
				'user'		=> @name,
				'secret'	=> @secret
			}
		end
  
		def startup channels=[]
			subscribe_to channels if channels.any?
		end
		
		def subscribe_to channels
			@subscriptions |= channels
			if @drone
				@drone.send_object 'subscribe', {'channels' => channels}
			end
		end
		
		def handle event, *args
			@handlers[event].call *args if @handlers.has_key? event
		end
		
		def receive_object action, data
			case action
				when 'auth'
					puts "logged in"
					handle :auth, data
				
				when 'private'
					puts "got private packet from #{data['from']}"
					handle :private, data['from'], data['data']
			
				when 'publish'
					puts "got public packet from #{data['from']} via #{data['channel']}"
					handle :publish, data['channel'], data['data']
			end
		end
	end
end
