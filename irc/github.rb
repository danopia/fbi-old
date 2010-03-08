require 'command_provider'

require 'yaml'
require 'open-uri'

def load_api *args
	YAML.load open("http://github.com/api/v2/yaml/#{args.join '/'}").read
end

fbi = CommandProvider.new 'github irc commands', 'hil0l'
	
fbi.cmd :repo do |data|
	if project = data['default_project']
		reply_to data, "The GitHub project for #{data['channel']} is at <http://github.com/#{data['default_project']}>. Clone command: `git clone git://github.com/#{data['default_project']}.git`"
	else
		reply_to data, "#{data['channel']} doesn't have a default project set up. Use the set-default project to add one."
	end
end
	
fbi.cmd :github do |data|
	begin
		cmd = data['args'].shift
		case cmd.downcase
			
			when 'issues'
				project = data['args'].last || data['default_project']
				
				open = load_api('issues', 'list', project, 'open')['issues']
				closed = load_api('issues', 'list', project, 'closed')['issues']
				
				message = "#{project} has #{open.size} open and #{closed.size} closed issues."
				
				if open.any?
					open.sort! {|a, b| b['updated_at'] <=> a['updated_at'] }
					message << " Recent issues: " + open[0,3].map{|issue| issue['title'] }.join(' || ')
				end
				
				reply_to data, message
		
			when 'ls'
				reply_to data, load_api('repos', 'show', data['args'].shift)['repositories'].map{|repo| repo[:name] + (repo[:fork] ? ' (fork)' : '')}.join(', ')
		
			when 'info'
				info = load_api('repos', 'show', data['args'].shift || data['default_project'])['repository']
				reply_to data, "#{info[:owner]}/#{info[:name]}: #{info[:description]} [#{info[:watchers]} watchers, #{info[:forks]} forks, #{info[:open_issues]} open issues]"

			when 'network'
				info = load_api('repos', 'show', data['args'].shift || data['default_project'], 'network')
				info = info['network'].map do |fork|
					"#{fork[:owner]}/#{fork[:name]}"
				end
				reply_to data, info.join(', ')

		end
	rescue OpenURI::HTTPError => e
		reply_to data, e.message
	rescue => e
		STDOUT.puts e.class, e.inspect, e.bactrace
	end
end

fbi.start_loop if $0 == __FILE__
