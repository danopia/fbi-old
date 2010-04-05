require 'socket'

module FBI_IRC

class Manager
	attr_accessor :nick_format, :ident, :realname, :networks, :channels, :handlers, :admins
	
	def initialize nick_format, ident=nil, realname=nil
		@nick_format = nick_format
		@ident = ident || nick_format
		@realname = realname || nick_format
		
		@channels = {}
		@networks = {}
		@handlers = {}
		@admins = ['danopia::EighthBit::staff', 'fullcirclemagazine/developer/danopia']
		
		# Only two come stock:
		# :ping (to pong)
		on :ping do |e|
			e.conn.force_send 'pong', e.params.first
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
		@handlers[event.to_sym || event] ||= []
		@handlers[event.to_sym || event] << blck
	end
	
	def unhook event
		@handlers.delete event.to_sym
	end
	
	def handle conn, event, origin, target, *params
		raise_event EventContext.new(conn, event, origin, target, params)
	end
	
	def raise_event e
		origin = (e.origin && e.origin[:nick]) || '<no origin>'
		target = e.target || '<no target>'
		puts "Handling #{e.event} from #{origin} to #{target} via #{e.conn.nick} with params #{e.params.join ' '}"
		
		return unless @handlers[e.event]
		
		@handlers[e.event].each {|block| block.call e }
	end
	
	def route_to chanid, message
		conn = @channels[chanid]
		channel = conn.channels[chanid]
		conn.message channel.name, message
	end
	
	def spawn_network record
		network = Network.new self, record
		@networks[record.id] = network
	end
end # manager class

class EventContext
	attr_reader :conn, :event, :origin, :target, :reply_to, :params
	
	def initialize conn, event, origin, target, params
		@conn = conn
		@event = event
		@origin = origin
		@target = target
		@params = params
		
		@reply_to = pm? ? origin : target
	end
	
	def network
		@conn.network
	end
	
	def manager
		@conn.network.manager
	end
	
	def param
		@params.join ' '
	end
	
	def pm?
		@conn.nick == @target
	end
	def channel?
		@conn.nick != @target
	end
	
	def ctcp?
		@event == :ctcp || @event == :ctcp_reply
	end
	
	def admin?
		manager.admin? origin
	end
	
	def message message
		@conn.message @reply_to, message
	end
	def notice message
		@conn.notice @reply_to, message
	end
	def action message
		@conn.action @reply_to, message
	end
	
	def respond message
		if ctcp?
			raise StandardError, 'cannot respond to a CTCP response' if @event == :notice
			@conn.ctcp_reply @origin, @params.first, message
			return
		end
		
		message = pm? ? message : "#{origin[:nick]}: #{message}"
		
		if @event == :notice
			self.notice message
		else
			self.message message
		end
	end
	
end # event_context class

class Network
	attr_reader :manager, :record, :channels, :connections, :next_id, :max_chans
	
	def initialize manager, record={}
		@manager = manager
		@record = record
		
		@connections = []
		@next_id = 1
		@max_chans = 20
		
		@channels = {}
		
		record.channels.each {|channel| join channel }
	end
	
	def message target, message
		bot = @channels[target] || @channels.values.first
		target = target.name if target.is_a? IrcChannel
		bot.message target, message
	end
	
	def join channel
		conn = @connections.find do |conn|
			conn.channels.size < @max_chans
		end
		
		conn ||= spawn_connection
		conn && conn.join(channel)
	end
	
	def part channel, message=nil
		@channels[channel].part channel, message
	end
	
	def quit message=nil
		@connections.each {|conn| conn.quit message }
		@connections.clear
	end
	
	def next_id!
		(@next_id += 1) - 1
	end
	
	def spawn_connection
		EventMachine::connect @record.hostname, @record.port, Connection, self
	rescue EventMachine::ConnectionError => ex
		puts "Error while connecting to IRC server #{@record.slug}: #{ex.message}"
		nil
	end
	
	def remove_conn conn
		@channels.each_pair do |chan, value|
			@channels.delete chan if value == conn
		end
		
		@connections.delete conn
	end
end # network class

class Connection < FBI::LineConnection
	attr_reader :network, :nick, :channels, :queue, :pending
	
	def initialize network
		super()
		network.connections << self

		@network = network
		@nick = network.manager.nick_format % network.next_id!
		@channels = {}
		
		send 'nick', @nick
		send 'user', @network.manager.ident, '0', '0', @network.manager.realname
		
		@pending = true
		@queue = []
	end
	
	def handle event, origin, target, *params
		@network.manager.handle self, event, origin, target, *params
	end
	
	def send_line packet
		packet = packet[0,472] + '...' if packet.size > 475
		
		if @pending
			@queue << packet
		else
			super packet
			puts "Sent as #{@nick}: #{packet}"
		end
	end
	
	def flush!
		puts "Flushing queue..."
		@pending = false
		while @queue.any?
			send_line @queue.shift
		end
		puts "Done flushing queue."
	end
	
	def send *params
		params.push ":#{params.pop}" if params.last.include? ' '
		
		params[0] = params[0].to_s.upcase
		params[1] = params[1][:nick] if params.size > 0 && params[1].is_a?(Hash)
		send_line params.join(' ')
	end
	
	# send through queue
	def force_send *params
		pending = @pending
		@pending = false
		send *params
		@pending = pending
	end
	
	def message target, message
		send :privmsg, target, message
	end
	def notice target, message
		send :notice, target, message
	end
	
	def ctcp target, command, args=''
		message target, build_ctcp(command, args)
	end
	def ctcp_reply target, command, args=''
		notice target, build_ctcp(command, args)
	end
	
	def action target, message
		ctcp target, 'action', message
	end
	
	def join channel
		send :join, channel.name # channel.key
		@channels[channel.id] = channel
		@network.channels[channel] = conn
		@network.manager.channels[channel.id] = conn
	end
	
	def part channel, msg=nil
		send :part, channel.name, msg || 'Leaving'
		@channels.delete channel.id
		@network.channels.delete channel
		@network.manager.channels.delete channel.id
	end
	
	def quit msg=nil
		send :quit, msg || 'Leave it to the FBI'
		@channels.clear
		@network.manager.channels.delete_if {|key, val| val == self }
	end
	
	def receive_line packet
		#puts packet
		parts = packet.split ' :', 2
		args = parts.shift.split
		args << parts.first if parts.any?
		
		origin = nil
		
		if args.first[0,1] == ':'
			parts = args.shift[1..-1].split('!', 2)
			
			origin = {:nick => parts.shift}
			
			if parts.any?
				origin[:ident], origin[:host] = parts[0].split '@', 2
			else
				origin[:server] = true
			end
		end
		
		command = args.shift.downcase
		
		case command
			when 'ping'
				handle :ping, origin, nil, *args
			
			when 'privmsg'
				handle_message :message, origin, args
			when 'notice'
				handle_message :notice, origin, args
				
			when 'join'
				handle :join, origin, *args
			when 'part'
				handle :part, origin, *args
			when 'quit'
				handle :quit, origin, nil, *args
				
			when '001'
				flush!
				handle :connected, origin, *args
				
			when /^[0-9]$/
				handle command.to_i, origin, args.shift, *args
				
			else
				handle :unhandled, origin, command, nil, *args
		end
	end
	
	protected
	
		def handle_message type, origin, args
			if ctcp? args[1]
				handle_ctcp type, origin, *args
			else
				handle type, origin, *args
			end
		end
		
		def ctcp? string
			string[0,1] == "\001" && string[-1,1] == "\001"
		end
		
		def handle_ctcp type, origin, target, message
			message = message[1..-2]
			args = message.split ' '
			command = args.shift.upcase
			type = (type == :message) ? :ctcp : :ctcp_response
			
			handle type, origin, target, command, args
		end
		
		def build_ctcp command, *args
			args.unshift command.upcase
			"\001#{args.join ' '}\001"
		end
end # connection class

end # module
