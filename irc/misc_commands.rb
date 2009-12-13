require 'command_provider'

class MiscCommands < CommandProvider
	auth 'misc irc commands', 'hil0l'
	
	on :meep do |data|
		reply_to data, 'Moop!'
	end
	
	on :convert do |data|
		types = data['args'].shift.split('->')
		number = data['args'].join ' '
		
		types.map! do |type|
			case type
				when 'hex': 16
				when 'dec': 10
				when 'oct': 7
				when 'ter': 3
				when 'bin': 2
				else; type.to_i
			end
		end
		
		reply_to data, number.to_i(types[0]).to_s(types[1])
	end
	
	on :bin2dec do |data|
		reply_to data, data['args'].join(' ').to_i(2).to_s
	end
	on :dec2bin do |data|
		reply_to data, data['args'].join(' ').to_i.to_s(2)
	end
	
	on :badtime do |data|
		reply_to data, (Time.now.utc+(11*60*60)).strftime('It is currently %I:%M:%S %p where baddog lives.')
	end
	
	on :fortune do |data|
		`fortune -s`.chomp.each_line do |line|
			reply_to data, line
		end
	end
	
	start
end
