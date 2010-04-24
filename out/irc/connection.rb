module FBI_IRC

class Connection < FBI::LineConnection
	attr_reader :network, :manager, :nick, :channels, :queue, :pending
	
	def initialize network
		super()

		@network = network
    @manager = @network.manager
    
		@network.connections << self
    
		@nick = @manager.nick_format % @network.next_id!
		
		send 'nick', @nick
		send 'user', @manager.ident, '0', '0', @manager.realname
		
		@pending = true
		@queue = []
		@channels = {}
	end
	
	def handle event, origin, target, *params
		target = @channels[target.downcase] || target if target
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
		ctcp target, :action, message
	end
	
	def join channel
    channel = Channel.new channel, self if channel.is_a? IrcChannel
    
		send :join, channel.to_s # channel.key
		@channels[channel.name.downcase] = channel
		@manager.channels[channel.id] = channel
	end
	
	def part channel, msg=nil
		send :part, channel.to_s, msg || 'Leaving'
		@channels.delete channel.to_s.downcase
		@manager.channels.delete channel.id
	end
	
	def quit msg=nil
		send :quit, msg || 'Leave it to the FBI'
		@channels.clear
		@network.remove_conn self
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
				handle_message :message, origin, *args
			when 'notice'
				handle_message :notice, origin, *args
				
			when 'join'
				handle :join, origin, *args
			when 'part'
				handle :part, origin, *args
			when 'quit'
				handle :quit, origin, nil, *args
				
			when 'nick'
				handle :nick, origin, *args
				
			when '001' # should be moved?
				flush!
				handle :connected, origin, *args
				handle 1, origin, args.shift, *args
				
			when /^[0-9]{3}$/
				handle command.to_i, origin, args.shift, *args
				
			else
				handle :unhandled, origin, command, nil, *args
		end
	end
	
	protected
	
		def handle_message type, origin, target, message
			if ctcp? message
				handle_ctcp type, origin, target, message
			else
				handle type, origin, target, message
			end
		end
		
		def ctcp? string
			string[0,1] == "\001" && string[-1,1] == "\001"
		end
		
		def handle_ctcp type, origin, target, message
			command, message = message[1..-2].split ' ', 2
			return unless command
			type = (type == :message) ? :ctcp : :ctcp_response
			handle type, origin, target, command.upcase, message
		end
		
		def build_ctcp command, *args
			args.unshift command.to_s.upcase
			"\001#{args.join ' '}\001"
		end
end # connection class

end # module
