module FBI_IRC

class Manager
	attr_accessor :nick_format, :ident, :realname, :networks, :channels, :handlers, :admins
	
	def initialize nick_format, ident=nil, realname=nil
		@nick_format = nick_format
		@ident = ident || nick_format
		@realname = realname || nick_format
		
		@channels = {}
		@networks = {}
		@handlers = Hash.new {|hash, key| hash[key] = [] }
		@admins = ['danopia::EighthBit::staff', 'fullcirclemagazine/developer/danopia']
		
		# Only two come stock:
		# :ping (to pong)
		on :ping do |e|
			e.conn.force_send :pong, e.params.first
		end
		
		# and :message (to emit :command)
		on :message do |e|
			params = e.param.split ' ', 3
			params.unshift e.conn.nick if e.pm?
			
			next if params.size < 2 || params.first.downcase.index(e.conn.nick.downcase) != 0
			next if params.first.size > e.conn.nick.size + 1
			
			params.shift
			handle e.conn, :command, e.origin, e.target, *params
			
			# For comchars
			#~ next if e.param.index(e.conn.nick) != 0
			#~ message = e.param[e.conn.nick.size..-1]
			#~ command, param = message.split ' ', 2
			#~ handle e.conn, :command, e.origin, e.target, command, param
		end
	end
	
	def admin? who
		@admins.include?(who.is_a?(Hash) ? who[:host] : who)
	end
	
	def on event, &blck
		@handlers[event.to_sym || event] << blck
	end
	
	def unhook event
		@handlers.delete(event.to_sym || event)
	end
	
	def handle conn, event, origin, target, *params
		raise_event EventContext.new(conn, event, origin, target, params)
	end
	
	def raise_event e
		origin = (e.origin && e.origin[:nick]) || '<no origin>'
		target = e.target || '<no target>'
		puts "Handling #{e.event} from #{origin} to #{target} via #{e.conn.nick} with params #{e.params.inspect}"
		
		@handlers[e.event].each {|block| block.call e }
	end
	
	def route_to channel, message
		channel = @channels[channel] || channel
		channel.message message
	end
	
	def spawn_network record
		network = Network.new self, record
		@networks[record.id] = network
	end
end # manager class

end # module
