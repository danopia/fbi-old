require File.join(File.dirname(__FILE__), '..', 'common', 'client')

class CommandProvider < FBI::Client
	attr_reader :commands
	
	def initialize *args
		super
		
		@commands = {}
		@subscriptions |= ['irc']
		
		on :publish do |channel, data|
			command = data['command'].to_sym
			next unless @commands.has_key? command
			@commands[command].call data
		end
	end
	
	def send_to server, channel, message
		private 'irc', {
			'id' => nil,
			'server' => server,
			'channel' => channel,
			'message' => message
		}
	end
	
	def reply_to data, message
		if data['channel'][0,1] == '#'
			message = "#{data['sender']['nick']}: #{message}"
		else
			data['channel'] = data['sender']['nick']
		end
		send_to data['server'], data['channel'], message
	end

	def cmd command, &blck
		@commands[command.to_sym] = blck
	end
end
