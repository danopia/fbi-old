require File.join(File.dirname(__FILE__), '..', 'common', 'client')

require File.join(File.dirname(__FILE__), 'irc_models')
require File.join(File.dirname(__FILE__), 'irc_lib')

$fbi = fbi = FBI::Client.new('irc', 'hil0l')

manager = FBI_IRC::Manager.new 'FBI-', 'fbi', 'FBI Version Control Informant'
$manager = manager

#manager.on :invite do |e|
#	e.conn.join e.target if e.channel?
#end

#new_irc.on_001 do
#	new_irc.msg 'NickServ', 'identify fbi *****'
#	new_irc.join server.channels.map{|chan| chan.name}.join(',')
#end

manager.on :ctcp do |e|
	case e.params.first
    when 'VERSION'
      e.respond 'FBI to_irc module v0.0.1'
     
    when 'PING'
      e.respond e.params.last.join(' ')
     
		when 'ACTION'
			message = e.params.last.join ' '
			
			e.action "_oø_ #{e.origin[:nick]}" if message.index("sets fire to #{e.conn.nick}") == 0
			e.action "shoots #{e.origin[:nick]}" if message.index("evades the FBI") == 0
			e.action "arrests #{e.origin[:nick]}" if message.index("mimics #{e.conn.nick}") == 0
			e.action "tastes crunchy" if message.index("eats #{e.conn.nick}") == 0
			e.action "dies" if message.index("kills #{e.conn.nick}") == 0
			e.action "hugs #{e.origin[:nick]}" if message.index("hugs #{e.conn.nick}") == 0
			e.message "ow" if message.index("kicks #{e.conn.nick}") == 0
			
			if message.index("rubs #{e.conn.nick}'s tummy") == 0
				if rand(2) == 1
					e.action "bites #{e.origin[:nick]}'s hand"
				else
					e.message "*purr*"
				end
			end

	end
end

manager.on :message do |e|
	e.respond "It's 'ooc', not 'OOC'!" if e.target == '#ooc-lang' && e.params.join.include?('OOC') && !e.params.join.include?('OOC_')
end

manager.on :command do |e|
	command = e.params[0]
	args = (e.params[1] || '').split
	
	case command.downcase
		when 'help'
			e.respond "My commands include help, list, default, set-default, add channel/project/server, and remove. There are some more but lowlings like you don't need to know them."
			
		when 'test'
			e.respond 'It worked!'
		
		when 'route'
			message = args[2..-1].join(' ')
			message = "\001ACTION #{$1}\001" if message =~ /^\/me (.+)$/i
			manager.networks[args[0].to_i].route_to args[1], message
			
		when 'list'
			server = Server.find e.network.id
			channel = server.channels.find_by_name e.target
			projects = channel.projects.map {|project| project.name }.join(', ')
			
			if channel.catchall
				e.respond "#{channel.name} is a catchall for all projects."
			else
				e.respond "Projects currently announcing to #{channel.name}: #{projects}."
			end
			
		when 'catchall'
			next unless e.admin?
			server = Server.find e.network.id
			channel = server.channels.find_by_name e.target
			channel.catchall = !channel.catchall
			channel.save
			
			if channel.catchall
				e.respond "#{channel.name} has been set to a catchall."
			else
				e.respond "#{channel.name} is no longer a catchall."
			end
			
		when 'default'
			server = Server.find e.network.id
			channel = server.channels.find_by_name e.target
			e.respond "The default GitHub project for #{channel.name} is #{channel.default_project}."
			
		when 'set-default'
			server = Server.find e.network.id
			channel = server.channels.find_by_name e.target
			channel.default_project = (args.shift.downcase rescue nil)
			channel.save
			e.respond "The default GitHub project for #{channel.name} is now #{channel.default_project}."
			
		when 'add'
			subcommand = args.shift.downcase
			if subcommand == 'project'
				server = Server.find e.network.id
				channel = server.channels.find_by_name e.target
				
				projects = []
				already_added = 0
				args.each do |arg|
					project = Project.find_by_name arg
					project = Project.create :name => arg unless project
					if channel.project_subs.find_by_project_id project.id
						already_added += 1
						next
					end
					
					channel.project_subs.create :project => project
					projects << project.name
				end
				
				e.respond "Added #{projects.join ', '} to this channel." + (already_added > 0 ? " (#{already_added} projects were already added.)" : '')
				
			elsif subcommand == 'channel'
				channel = Channel.create :server_id => e.network.id, :name => args.shift
				e.network.join channel.name
				e.respond "Joined #{channel.name}."
				
			elsif subcommand == 'server'
				server = Server.create :hostname => args.shift
				channel = server.channels.create :name => args.shift
				if manager.spawn_from_record server
					e.respond "Connecting to #{server.hostname}, and I'll join #{channel.name} once I'm there."
				else
					e.respond "There was an error connecting to #{server.hostname}."
				end
			end
		
		when 'remove'
			if args.first == 'for real'
				server = Server.find e.network.id
				channel = server.channels.find_by_name e.target
				channel.subscriptions.each do |subscription|
					subscription.delete!
				end
				channel.delete!
				e.respond "#{e.target} has been completely removed from FBI."
				e.network.part channel
			else
				e.respond "To confirm completely removing this channel from FBI, please use the 'remove for real' command."
			end
		
		else
			puts "Unknown command #{command}; broadcasting a packet"
			server = Server.find e.network.id
			channel = server.channels.find_by_name e.target
			$fbi.publish 'irc', {
				:server => e.network.id,
				:channel => e.target,
				:sender => e.origin,
				:command => command,
				:args => e.params[1],
				:admin => e.admin?,
				:default_project => channel && channel.default_project,
			}
	end
end

if Server.all.size == 0
	channel = Channel.new :name => '#bots'
	channel.server = Server.create :hostname => '76.73.53.189'
	channel.save
	
	project = Project.create :name => 'fbi'
	
	channel.project_subs.create :project => project
	
	Channel.create :name => '#commits', :server => channel.server, :catchall => true
end

Server.all.each do |server|
	manager.spawn_from_record server
end

def route project, message
	channels = Channel.find_all_by_catchall true
	
	project = Project.find_by_name project
	channels |= project.channels if project
	
	channels.each do |channel|
		$manager.route_to channel.server_id, channel.name, message
		#sleep 0.5
	end
end

fbi.on :published do |channel, data|
	if channel == 'commits'
		commits = data
		commits = commits[-3..-1] if commits.size > 3
		commits.each do |commit|
			if commit['fork']
				commit['owner'] << '/'
			else
				commit['owner'] = ''
			end

			message = "#{commit['owner']}\002#{commit['project']}:\017 \00303#{commit['author']['name']} \00307#{commit['branch']}\017 \002#{commit['commit'][0,8]}\017: #{commit['message'].gsub("\n", ' ')} \00302<\002\002#{commit['shorturl']}>"

			route commit['project'], message
		end
		
	elsif channel == 'mailinglist'
		data.each do |post|
			message = "\002#{post['project']} mailing list:\017 \00303#{post['author']['name']}\017 : #{post['subject'].gsub("\n", ' ')} \00302<\002\002#{post['shorturl']}>"

			route post['project'], message
		end
	end
end

fbi.on :private do |from, data|
	$manager.route_to data['server'], data['channel'], data['message']
end

fbi.subscribe_to 'commits', 'mailinglist'
fbi.connect
EventMachine.run {} if $0 == __FILE__
