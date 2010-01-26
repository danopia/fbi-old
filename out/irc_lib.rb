require "socket"

module FBI_IRC

class Manager
	attr_accessor :base_nick, :ident, :realname, :networks, :handlers, :admins
	
	def initialize(base_nick, ident=nil, realname=nil)
		@base_nick = base_nick
		@ident = ident || base_nick
		@realname = realname || base_nick
		
		@networks = {}
		@handlers = {}
		@admins = ['danopia::EighthBit::staff', 'fullcirclemagazine/developer/danopia']
		
		# Only two come stock:
		# :ping (to pong)
		on :ping do |e|
			p e.params
			e.conn.send 'pong', e.param, true
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
		@handlers[event.to_sym] ||= []
		@handlers[event.to_sym] << blck
	end
	
	def unhook event
		@handlers.delete event.to_sym
	end
	
	def handle conn, event, origin, target, *params
		raise_event EventContext.new(conn, event, origin, target, params)
	end
	
	def raise_event e
		puts "Handling #{e.event} from #{e.origin[:nick]} to #{e.target} via #{e.conn.nick} with params #{e.params.join ' '}" if e.origin
		
		return unless @handlers[e.event]
		
		@handlers[e.event].each do |block|
			block.call e
		end
	end
	
	def route_to network, channel, message
		@networks[network].route_to channel, message
	end
	
	def spawn_network config
		network = Network.new self, config
		@networks[network.id] = network # TODO: Only does one connection/ip (ports anyone?)
	end
	
	def spawn_from_record record
		EM.next_tick do
			spawn_network :id => record.id, :server => record.hostname, :port => record.port, :channels => record.channels.map{|chan| chan.name}
		end
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
	attr_reader :manager, :config, :server, :port, :channels, :connections, :next_id, :id
	
	def initialize manager, config={}
		@manager = manager
		@config = config
		
		@server = config[:server]
		@port = config[:port]
		@connections = []
		@next_id = 1
		@id = config[:id] || @server
		
		@channels = {}
		
		return unless config[:channels]
		config[:channels].each do |channel|
			join channel
		end
	end
	
	def route_to channel, message
		(@channels[channel.downcase] || @channels.values.first).message channel, message
	end
	
	def join channel, key=nil
		conn = @connections.find do |conn|
			conn.channels.size < 20
		end
		
		unless conn
			conn = spawn_connection
		end
		
		if conn
			@channels[channel.downcase] = conn
			conn.join channel, key
		end
	end
	
	def part channel, message
		@channels[channel.downcase].part channel, message
		@channels.delete channel.downcase
	end
	
	def quit message=nil
		@connections.each do |conn|
			conn.quit message
		end
		
		@connections.clear
	end
	
	def spawn_connection
		conn = EventMachine::connect @server, (@port || 6667), Connection, self
		@next_id += 1
		conn
	rescue EventMachine::ConnectionError => ex
		puts "Error while connecting to IRC server #{@server}:#{@port||6667}: #{ex.message}"
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
	attr_reader :network, :nick, :channels
	
	def initialize network
		super()
		network.connections << self

		@network = network
		@nick = "#{network.manager.base_nick}#{network.next_id}"
		@channels = []
		
		send 'nick', @nick
		send 'user', @network.manager.ident, '0', '0', @network.manager.realname, true
		#join @channels.join(',')
	end
	
	def handle event, origin, target, *params
		@network.manager.handle self, event, origin, target, *params
	end
	
	def send_line packet
		packet = packet[0,497] + '...' if packet.size > 500
		super packet
		puts "Sent as #{@nick}: #{packet}"
	end
	
	# true as last arg puts a : before the last param
	def send *params
		if params.last == true || params.last.include?(' ')
			params.pop if params.last == true
			params.push ":#{params.pop}"
		end
		
		params[0].upcase!
		params[1] = params[1][:nick] if params.size > 0 && params[1].is_a?(Hash)
		send_line params.join(' ')
	end
	
	def message target, message
		send 'privmsg', target, message, true
	end
	def notice target, message
		send 'notice', target, message, true
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
	
	def join channel, key=nil
		# TODO: keys
		raise StandardError, "channel keys aren't handled yet" if key
		
		send 'join', channel
		@channels << channel.downcase
	end
	def part channel, msg=nil
		send 'part', channel, msg || 'Leaving', true
		@channels.delete channel.downcase
	end
	
	def quit msg=nil
		send 'quit', msg || 'Leave it to the FBI', true
		@channels.clear
	end
	
	def receive_line packet
		puts packet
		parts = packet.split ' :', 2
		args = parts[0].split ' '
		args << parts[1] if parts.size > 1
		
		origin = nil
		
		if args.first[0,1] == ':'
			parts = (args.shift)[1..-1].split('!', 2)
			if parts.size > 1
				parts[1], parts[2] = parts[1].split('@', 2)
				origin = {:ident => parts[1], :host => parts[2]}
			else
				origin = {:server => true}
			end
			
			origin[:nick] = parts[0]
		end
		
		command = args.shift
		
		case command.downcase
			when 'ping'
				handle :ping, origin, *args
			
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
	
	def build_ctcp command, args=''
		command.upcase!
		args = args.join ' ' if args.is_a? Array
		command << " #{args}" if args.any?
		"\001#{command}\001"
	end
end # connection class

end # module
