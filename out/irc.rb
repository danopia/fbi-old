require File.join(File.dirname(__FILE__), '..', 'common', 'client')

require File.join(File.dirname(__FILE__), 'irc_models')
require File.join(File.dirname(__FILE__), 'irc_lib')

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
      e.respond 'FBI to_irc module v0.1'
     
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

manager.on :command do |e|
	command = e.params[0]
	args = (e.params[1] || '').split
	
	case command.downcase
		when 'test'
			e.respond 'It worked!'
		
		when 'route'
			manager.networks[args[0].to_i].route_to args[1], args[2..-1].join(' ')
			
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
				manager.spawn_from_record server
				e.respond "Connecting to #{server.hostname}, and I'll join #{channel.name} once I'm there."
			end
		
		else
			server = Server.find e.network.id
			channel = server.channels.find_by_name e.target
			FBI::Client.publish 'irc', {
				:server => e.network.id,
				:channel => e.target,
				:sender => e.origin,
				:command => command,
				:args => args,
				:admin => e.admin?,
				:default_project => channel.default_project,
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

Thread.new { manager.run }

def route project, message
	channels = Channel.find_all_by_catchall true
	
	project = Project.find_by_name project
	channels |= project.channels if project
	
	channels.each do |channel|
		$manager.route_to channel.server_id, channel.name, message
		sleep 0.5
	end
end


FBI::Client.on_published do |channel, data|
	data['project2'] << '/' if data['project2']
	message = "#{data['project2']}\002#{data['project']}:\017 \00303#{data['author']['name']} \00307#{data['branch']}\017 \002#{data['commit'][0,8]}\017: #{data['message'].gsub("\n", ' ')} \00302<\002\002#{data['shorturl']}>"
	
	route data['project'], message
end

FBI::Client.on_private do |from, data|
	$manager.route_to data['server'], data['channel'], data['message']
end


FBI::Client.start_loop 'irc', 'hil0l', ['commits']
