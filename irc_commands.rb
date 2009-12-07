require 'common/client'

def reply_to data, message
	message = "#{data['sender']['nick']}: #{message}" if data['sender']['nick'] != data['channel']
	hash = {
		'id' => nil,
		'server' => data['server'],
		'channel' => data['channel'],
		'message' => message
	}
	
	FBI::Client.private 'irc', hash
end

FBI::Client.on_published do |channel, data|
	case data['command']
		when 'meep'
			reply_to data, 'Moop!'
	end
end

FBI::Client.start_loop 'irccommands', 'hil0l', ['irc']
