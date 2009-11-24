# irc.rb: Ruby IRC bot library
# Copyright (c) 2009 Nick Markwell (duckinator/RockerMONO on irc.freenode.net)
# usage:
#   irc = IRC.new("irc.freenode.net", 6667, "ircbot1", "#botters")
#  	irc.connect
#   irc.main_loop
 
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
		@admins = ['danopia::EighthBit::staff']
		
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
			
			next if params.size < 2 || params.first.index(e.conn.nick) != 0
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
	
	# Just keep on truckin'. Forever.
	def run
		handle_socks while true
	end
	
	def handle_socks
		ready = select self.socks, nil, self.socks
		return unless ready
		
		(ready[0] + ready[2]).each do |sock|
			sock.connection.read_packet
		end
	end
	
	def spawn_network config
		network = Network.new self, config
		@networks[network.id] = network # TODO: Only does one connection/ip (ports anyone?)
	end
	
	def spawn_from_record record
		spawn_network :id => record.id, :server => record.hostname, :port => record.port, :channels => record.channels.map{|chan| chan.name}
	end
	
	protected
	
	def socks
		@networks.values.map {|network| network.socks }.flatten
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
		@channels[channel.downcase].message channel, message
	end
	
	def join channel, key=nil
		conn = @connections.find do |conn|
			conn.channels.size < 3
		end
		
		unless conn
			conn = spawn_connection
		end
		
		@channels[channel.downcase] = conn
		conn.join channel, key
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
		conn = Connection.spawn self
		@next_id += 1
		conn
	end
	
	def remove_conn conn
		@channels.each_pair do |chan, value|
			@channels.delete chan if value == conn
		end
		
		@connections.delete conn
	end
	
	def socks
		@connections.map {|conn| conn.sock }
	end
end # network class

class Connection
	attr_reader :network, :nick, :sock, :channels
	
	def self.spawn network
		conn = self.new network
		conn.connect
		network.connections << conn
		conn
	end
	
	def initialize network
		@network = network
		@nick = "#{network.manager.base_nick}#{network.next_id}"
		@channels = []
	end
	
	def handle event, origin, target, *params
		@network.manager.handle self, event, origin, target, *params
	end
	
	def send_raw packet
		packet = packet[0,497] + '...' if packet.size > 500
		@sock.puts packet
		puts "Sent as #{@nick}: #{packet}"
	rescue Errno::EPIPE => e
		puts "Caught EPIPE! (I'm #{@nick}) #{e.message}"
	rescue Errno::ECONNRESET => e
		puts "Connection reset by peer! (I'm #{@nick})"
	end
	
	# true as last arg puts a : before the last param
	def send *params
		if params.last == true || params.last.include?(' ')
			params.pop if params.last == true
			params.push ":#{params.pop}"
		end
		
		params[0].upcase!
		params[1] = params[1][:nick] if params.size > 0 && params[1].is_a?(Hash)
		send_raw params.join(' ')
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
	
	def connect
		puts "Connecting to #{@network.server}:#{@network.port || 6667} as #{@nick}"
		@sock = TCPSocket.open @network.server, @network.port || 6667
		
		@sock.instance_variable_set '@connection', self
		def @sock.connection
			@connection
		end
		
		send 'nick', @nick
		send 'user', @network.manager.ident, '0', '0', @network.manager.realname, true
		#join @channels.join(',')
	end
	
	def read_packet
		packet = @sock.gets
		handle_packet packet.chomp if packet
	rescue Errno::ECONNRESET => e
		puts "Connection reset by peer when reading. I'm #{@nick} on #{@network.server}."
		@network.remove_conn self
	end
	
	def handle_packet packet
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
