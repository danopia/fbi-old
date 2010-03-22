require File.join(File.dirname(__FILE__), 'drone')

module FBI
	class Client
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
			EventMachine.next_tick {
				startup Drone.connect(self, args)
			}
		end
		def start_loop *args
			EventMachine::run { connect *args }
		end
		
		def send target, data
			@drone.send_object 'publish', {
				'target'	=> target,
				'data'		=> data
			}
		end
		
		def login
			@drone.send_object 'auth', {
				'user'		=> @name,
				'secret'	=> @secret
			}
		end
		
		def send_object *args
			@drone.send_object *args
		end
  
		def startup drone
			@drone = drone
			login
			subscribe_to *@subscriptions if @subscriptions.any?
		end
		
		def subscribe_to *channels
			@subscriptions |= channels
			if @drone
				@drone.send_object 'subscribe', {'channels' => channels}
			end
		end
		
		def handle event, *args
			@handlers[event].call *args if @handlers.has_key? event
		end
		
		def receive_object action, data
			p data
			case action
				when 'auth'
					puts "logged in as #{data['user']}"
					handle :authed, data
					
				when 'subscribe'
					puts "subscribed to #{data['channels'].join ', '}"
					handle :subscribed, data['channels']
				
				when 'publish'
					puts "packet from #{data['origin']} to #{data['target']}"
					handle :publish, data['origin'], data['target'], data['target'] == @name, data['data']
			end
		rescue => ex
			p ex, ex.message, ex.backtrace
		end
		
		def reconnect delay=3
			@drone.close_connection
			@drone = nil
			puts "Router dropped connection, reconnecting to the router in #{delay} seconds..."
			EM.add_timer(delay) { connect }
		end
	end
end
