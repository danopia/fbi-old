require File.join(File.dirname(__FILE__), '..', 'common', 'client')
require File.join(File.dirname(__FILE__), '..', 'common', 'models')

require File.join(File.dirname(__FILE__), 'irc_lib')

$fbi = fbi = FBI::Client.new('irc (dev)', 'hil0l')

$manager = manager = FBI_IRC::Manager.new('FBI-%i[dev]', 'fbi', 'FBI Version Control Informant')

#manager.on :invite do |e|
#	e.conn.join e.target if e.channel?
#end

#new_irc.on_001 do
#	new_irc.msg 'NickServ', 'identify fbi *****'
#	new_irc.join server.channels.map{|chan| chan.name}.join(',')
#end

manager.on :ctcp do |e|
	case e[0]
	
    when 'VERSION'
      e.respond 'FBI to_irc module v0.0.1'
     
    when 'PING'
      e.respond e[1]
     
		when 'ACTION'
			message = e[1]
			
			e.action "_oø_ #{e.origin[:nick]}" if message.index("sets fire to #{e.conn.nick}") == 0
			e.action "shoots #{e.origin[:nick]}" if message.index("evades the FBI") == 0
			e.action "arrests #{e.origin[:nick]}" if message.index("mimics #{e.conn.nick}") == 0
			e.action "tastes crunchy" if message.index("eats #{e.conn.nick}") == 0
			e.action "dies" if message.index("kills #{e.conn.nick}") == 0
			e.action "smacks #{e.origin[:nick]} even harder" if message.index("smacks #{e.conn.nick}") == 0
			e.action "hugs #{e.origin[:nick]}" if message.index("hugs #{e.conn.nick}") == 0
			e.message "That's a pathetic excuse for a slap, #{e.origin[:nick]}." if message.index("slaps #{e.conn.nick}") == 0
			e.message "ow" if message.index("kicks #{e.conn.nick}") == 0
			
			if message.index("rubs #{e.conn.nick}'s tummy") == 0
				if rand(2).zero?
					e.action "bites #{e.origin[:nick]}'s hand"
				else
					e.message "*purr*"
				end
			end

	end
end

manager.on :message do |e|
	e.respond "It's 'ooc', not 'OOC'!" if e.target.to_s == '#ooc-lang' && e.params.first.include?('OOC') && !e.params.first.include?('OOC_')
	
	next unless e.target.is_a? FBI_IRC::Channel
	
	fbi.send '#irc', {
		:channel => e.target.id,
		:sender => e.origin,
		:message => e[0],
		:admin => e.admin?,
	} rescue nil
end

manager.on 005 do |e|
	if e.params.find {|cap| cap =~ /^NETWORK=(.+)/ }
		e.network.record.title = $1
		e.network.record.save
	end
	
	if e.params.find {|cap| cap =~ /^CHANLIMIT=(.+)/ }
		limits = $1.scan(/([#~&!+]):([0-9]+)/)
		limit = limits.find{|caps| caps[0].include? '#'}
		e.network.max_chans = limit[1].to_i if limit
	end
	
	e.conn.send :protoctl, 'NAMESX' if e.params.include? 'NAMESX'
end


###################
# User tracking

manager.on :join do |e|
	e.target.users << e.origin[:nick]
end

manager.on :part do |e|
	e.target.is_a?(FBI_IRC::Channel) && e.target.users.delete(e.origin[:nick])
end

manager.on :kick do |e|
	p e.params
	e.target.is_a?(FBI_IRC::Channel) && e.target.users.delete(e[2])
end

manager.on :quit do |e|
	e.conn.channels.each_value {|chan| chan.users.delete e.origin[:nick] }
end

manager.on 353 do |e|
	channel = e.conn.channels[e[1].downcase]
	
	channel.users = [] unless channel.in_names
	channel.in_names = true
	
	channel.users += e[2].split
end

manager.on 366 do |e|
	channel = e.conn.channels[e[0].downcase]
	channel.in_names = false
end

# End user tracking
###################


def fetch_identities network, origin
	ids = Identity.where :service_id => 2
	ids = ids.select do |ident|
		next false if ident.json['network_id'] != network.record.id
		
		pattern = ident.key
		actual = "#{origin[:nick]}!#{origin[:ident]}@#{origin[:host]}"
		#p pattern, actual, '^' + Regexp.escape(pattern).gsub("\\*", '.*') + '$'
		Regexp.new('^' + Regexp.escape(pattern).gsub("\\*", '.*') + '$').match actual
	end
	
	ids.first
end

manager.on :command do |e|
	command = e[0]
	args = e[1..-1]
	
	case command.downcase
		#~ when 'help'
			#~ e.respond "My commands include help, list, default, set-default, add channel/project/server, and remove. There are some more but lowlings like you don't need to know them."
			
		when 'test'
			e.respond 'It worked!'
		
		when 'route'
			channel = manager.channels[args.shift.to_i]
			message = args.join(' ')
			message.sub! /^\/me (.+)$/i, "\001ACTION \1\001"
			channel.message message

		when 'route_for'
			route args.shift.to_i, nil, args.join(' ')
			
		when 'projects'
			projects = e.target.record.projects.map {|project| project.title }
			#~ if channel.catchall
				#~ e.respond "#{e.target} is a catchall for all projects."
			#~ else
				e.respond "Projects currently announcing to #{e.target}: #{projects.join(', ')}"
			#~ end
			
		when 'project'
			projects = e.target.record.projects
			case (args.shift||'').downcase
			
				when 'add'
					args.map! do |arg|
						project = Project.find :slug => arg
						project ||= Project.find :title => arg
						
						if !project
							"#{project.title} doesn't exist"
						elsif projects.include? project
							"#{project.title} was already added"
						else
							e.target.record.create_sub project
							"#{project.title} was added"
						end
					end
					
					e.respond "Results: #{args.join ', '}"
			
				when 'remove', 'rm'
					args.map! do |arg|
						project = projects.find {|proj| proj.slug == arg || proj.title == arg }
						
						if !project
							"#{project.title} doesn't exist"
						elsif projects.include? project
							e.target.record.sub_for(project).destroy!
							"#{project.title} was removed"
						else
							"#{project.title} wasn't added"
						end
					end
					
					e.respond "Results: #{args.join ', '}"

			end
			
		when 'whoami'
			ids = Identity.where :service_id => 2
			ids = ids.select do |ident|
				next false if ident.json['network_id'] != e.network.record.id
				
				pattern = ident.key
				actual = "#{e.origin[:nick]}!#{e.origin[:ident]}@#{e.origin[:host]}"
				#p pattern, actual, '^' + Regexp.escape(pattern).gsub("\\*", '.*') + '$'
				Regexp.new('^' + Regexp.escape(pattern).gsub("\\*", '.*') + '$').match actual
			end
			
			if ids.empty?
				e.respond 'Nobody.'
			elsif ids.size == 1
				id = ids.first
				e.respond "You are authed as #{id.user.display_name}."
			else
				e.respond "You match #{ids.size} identities, so I'll consider you no one."
			end
			
		when 'authorize'
			user = User.find :username => args.shift
			
			if user.nil?
				e.respond 'The username or password was incorrect.'
			elsif user.password_hash != User.hash(user.username.downcase, user.salt, args.shift)
				e.respond 'The username or password was incorrect.'
			else
			
				ident = user.new_identity
				ident.key = "#{e.origin[:nick]}!#{e.origin[:ident]}@#{e.origin[:host]}"
				ident.json = {:network_id => e.network.record.id}
				ident.service_id = 2
				ident.save
				
				e.respond "An identity for #{ident.key} on #{e.network.record.title} has been added to #{user.display_name}. I will now recognize you on IRC automatically."
			end
			
		when 'register'
			user = User.new
			user.username, user.email, user.password = args
		  user.save
		  
			ident = user.new_identity
			ident.key = "#{e.origin[:nick]}!#{e.origin[:ident]}@#{e.origin[:host]}"
			ident.json = {:network_id => e.network.record.id}
			ident.service_id = 2
			ident.save
				
			e.respond "Your account, #{user.display_name}, has been created. You may now log in to the website. An identity matching #{ident.key} on #{e.network.record.title} has already been added to your account so that I can recognize you on IRC automatically."
			
		when 'join'
			channel = e.network.record.channel_by :name => args[0]
			channel ||= e.network.record.create_channel :name => args[0]
			e.conn.join channel
			
		#~ when 'catchall'
			#~ next unless e.admin?
			#~ server = Server.find e.network.id
			#~ channel = server.channels.find_by_name e.target
			#~ channel.catchall = !channel.catchall
			#~ channel.save
			#~ 
			#~ if channel.catchall
				#~ e.respond "#{channel.name} has been set to a catchall."
			#~ else
				#~ e.respond "#{channel.name} is no longer a catchall."
			#~ end
			#~ 
		#~ when 'default'
			#~ server = Server.find e.network.id
			#~ channel = server.channels.find_by_name e.target
			#~ e.respond "The default GitHub project for #{channel.name} is #{channel.default_project}."
			#~ 
		#~ when 'set-default'
			#~ server = Server.find e.network.id
			#~ channel = server.channels.find_by_name e.target
			#~ channel.default_project = (args.shift.downcase rescue nil)
			#~ channel.save
			#~ e.respond "The default GitHub project for #{channel.name} is now #{channel.default_project}."
		
		else
			puts "Unknown command #{command}; broadcasting a packet"
			next unless e.target.is_a? FBI_IRC::Channel
			
			fbi.send '#irc', {
				:channel => e.target.id,
				:sender => e.origin,
				:command => command,
				:args => e[1],
				:admin => e.admin?,
			} rescue nil
	end
end



EM.next_tick {
	networks = $DEBUG ? [IrcNetwork.find(:id => 3)] : IrcNetwork.all
	networks.each do |network|
		manager.spawn_network network
	end
}

# TODO: This should just get a list of channel IDs without pulling channel objects
def route project_id, repo_id, message
	# channels = Channel.find_all_by_catchall true
	
	project = Project.find :id => project_id
	return unless project
	
	if repo_id
		repo = project.repo_by :id => repo_id
		
		prefixed_message = "\002#{project.title}\017/#{repo.title}: #{message}"
		message = "\002#{repo.title}\017/: #{message}"
	else
		prefixed_message = "\002#{project.title}\017/: #{message}"
	end
	
	project.irc_channels.each do |channel|
		channel = $manager.channels[channel.id]
		next unless channel
		
		channel.message (channel.record.project_id == project.id) ? message : prefixed_message
		#sleep 0.5
	end
end

fbi.on :publish do |origin, target, private, data|
	if target == '#commits'
		commits = data['commits']
		
		if commits.size > 3
			commits = commits[-3..-1]
			commits.first['message'] = "(#{data.size - commits.size - 3} commit(s) ignored --FBI)\n#{commits.first['message']}"
		end
		
		commits.each do |commit|
			message = "\00303#{commit['author']['name']} \00307#{data['branch']}\017 \002#{commit['commit'][0,8]}\017: #{commit['message'].gsub("\n", ' ')} \00302<\002\002#{commit['shorturl'] || commit['url']}>"

			route data['project_id'], data['repo_id'], message
		end
		
	elsif target == '#mailinglist'
		data.each do |post|
			message = "mailing list: \00303#{post['author']['name']}\017 : #{post['subject'].gsub("\n", ' ')} \00302<\002\002#{post['shorturl']}>"

			#route post['project'], message
		end
		
	elsif target == '#irc'
		case data['mode']
		
			when 'connect'
				next if manager.networks.has_key? data['network_id']
				
				network = IrcNetwork.find data['network_id']
				manager.spawn_network network if network
		
			when 'disconnect'
				next unless manager.networks.has_key? data['network_id']
				
				network = manager.networks[data['network_id']]
				network.quit data['message']
				
				manager.networks.delete data['network_id']
				
			when 'join'
				channel = IrcChannel.find data['channel_id']
				next if !channel
				
				if manager.networks.has_key? channel.network_id
					network = manager.networks[channel.network_id]
					network.join channel
				else
					manager.spawn_network channel.network
				end
				
			when 'message'
				channel = manager.channels[data['channel_id']]
				channel && channel.message(data['message'])
				
			when 'users'
				channel = manager.channels[data['channel_id']]
				
				unless channel
					fbi.send origin,
						:mode => 'users',
						:response => true,
						:channel_id => data['channel_id'],
						:users => [],
						:error => true
				end
				
				fbi.send origin,
					:mode => 'users',
					:response => true,
					:channel_id => channel.id,
					:users => channel.users
				
			when 'route'
				route data['project_id'], data['repo_id'], data['message']
				
			when 'part'
				channel = manager.channels[data['channel_id']]
				channel && channel.part(data['message'])
				
			when 'cycle'
				channel = manager.channels[data['channel_id']]
				next unless channel
				
				channel.part data['message']
				
				network = manager.networks[channel.record.network_id]
				network.join channel
			
		end
		
	end
end

fbi.subscribe_to '#commits', '#mailinglist', '#irc'
fbi.connect

EventMachine.run {} if $0 == __FILE__
