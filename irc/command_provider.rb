require File.join(File.dirname(__FILE__), '..', 'common', 'client')

class CommandProvider
	@@commands = {}
	@@client = nil
	@@username = nil
	@@password = nil
	
	def self.auth username, password
		@@username = username
		@@password = password
	end
	
	def self.start &blck
		FBI::Client.on_published do |channel, data|
			@@commands[data['command'].to_sym].call data rescue nil
		end
		
		EventMachine::run {
			yield false if blck && blck.arity > 0
			@@client = FBI::Client.connect @@username, @@password, ['irc']
			yield true if blck
		}
	end
	
	def self.send_to server, channel, message
		FBI::Client.private 'irc', {
			'id' => nil,
			'server' => server,
			'channel' => channel,
			'message' => message
		}
	end
	
	def self.reply_to data, message
		if data['channel'][0,1] == '#'
			message = "#{data['sender']['nick']}: #{message}"
		else
			data['channel'] = data['sender']['nick']
		end
		send_to data['server'], data['channel'], message
	end

	def self.on command, &blck
		@@commands[command.to_sym] = blck
	end
end
