$LOAD_PATH << './../common'
require 'receiver'
require 'irc_lib'

require 'irc_models'

manager = FBI_IRC::Manager.new 'FBIv2-', 'fbi', 'FBI Version Control Informant'

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
      e.respond e.params.last
     
		when 'ACTION'
			message = e.params.last.join ' '
			
			e.action "shoots #{e.origin[:nick]}" if message.index("evades the FBI") == 0
			e.action "tastes crunchy" if message.index("eats FBI") == 0
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
			channel = Channel.find_by_name e.target
			projects = channel.projects.map {|project| project.name }.join(', ')
			e.respond "Projects currently announcing to #{channel.name}: #{projects}."
			
		when 'add'
			if args[0] == 'project'
				project = Project.find_by_name args[1]
				project = Project.create :name => args[1] unless project
				channel = Channel.find_by_name e.target
				channel.project_subs.create :project => project
				e.respond "Added #{project.name} to this channel."
				
			elsif args[0] == 'channel'
				channel = Channel.create :server_id => e.network.id, :name => args[1]
				e.network.join channel.name
				e.respond "Joined #{channel.name}."
				
			elsif args[0] == 'server'
				server = Server.create :hostname => args[1]
				channel = server.channels.create :name => args[2]
				manager.spawn_from_record server
				e.respond "Connecting to #{server.hostname}, and I'll join #{channel.name} once I'm there."
			end
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

@receiver = Receiver.new 'irc2'

@receiver.on_message do |project, message|
	channels = Channel.find_all_by_catchall true
	
	project_rec = Project.find_by_name project
	channels |= project_rec.channels if project_rec
	
	channels.each do |channel|
		manager.route_to channel.server_id, channel.name, "\002#{project}:\017 #{message}"
		sleep 1
	end
end

Thread.new { @receiver.run }
manager.run
