require 'command_provider'

require 'yaml'
require 'open-uri'

def load_api *args
	YAML.load open("http://github.com/api/v2/yaml/#{args.join '/'}").read
end

class GithubCommands < CommandProvider
	auth 'github irc commands', 'hil0l'
	
	on :github do |data|
		begin
			cmd = data['args'].shift
			case cmd.downcase
			
				when 'ls'
					reply_to data, load_api('repos', 'show', data['args'].shift)['repositories'].map{|repo| repo[:name]}.join(', ')
			
				when 'info'
					info = load_api('repos', 'show', data['args'].shift)['repository']
					reply_to data, "#{info[:owner]}/#{info[:name]}: #{info[:description]} [#{info[:watchers]} watcher(s), #{info[:forks]} fork(s)]"
	
				when 'network'
					info = load_api('repos', 'show', data['args'].shift, 'network')
					info = info['network'].map do |fork|
						"#{fork[:owner]}/#{fork[:name]}"
					end
					reply_to data, info.join(', ')
	
			end
		rescue OpenURI::HTTPError => e
			reply_to data, e.message
		end
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
