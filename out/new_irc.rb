$LOAD_PATH << './../common'
require 'receiver'

require 'irc_models'

if Server.all.size == 0
	channel = Channel.new :name => '#bots'
	channel.server = Server.create :hostname => 'irc.eighthbit.net'
	channel.save
	
	project = Project.create :name => 'fbi'
	
	channel.project_subs.create :project => project
end

@connections = {}
@parser = Parser.new
@receiver = Receiver.new 'irc2'

@receiver.on_message do |project, message|
	project = Project.find_by_name project
	next unless project
	
	project.channels.each do |channel|
		@connections[channel.server.id].msg channel.name, "\002#{project.name}:\017 #{message}"
		sleep 1
	end
end

def add_network(server)
	new_irc = IRC.new(
		:server => server.hostname,
		:port => server.port || 6667,
		:nick => 'FBI',
		:ident => 'fbi',
		:realname => 'FBI bot - powered by on_irc Ruby IRC library',
		:options => { :use_ssl => false }
	)
	@connections[server.id] = new_irc
	
	new_irc.on_all_events do |e|
		p e
	end
	new_irc.on_invite do |e|
		value.join e.channel
	end
	new_irc.on_001 do
		new_irc.msg 'NickServ', 'identify fbi hil0l'
		new_irc.join server.channels.map{|chan| chan.name}.join(',')
	end

	new_irc.on_privmsg do |e|
		@parser.command(e, 'calc') do |c, params|
			url = "http://www.google.com/search?q=#{ERB::Util.u(c.message)}"
			doc = Hpricot open(url)
			calculation = (doc/'#res/p/table/tr/td[3]/h2/font/strong').inner_html
			if calculation.empty?
				new_irc.msg(e.recipient, 'Invalid Calculation.')
			else
				new_irc.msg(e.recipient, calculation.gsub(/&#215;/,'*').gsub(/<sup>/,'^').gsub(/<\/sup>/,'').gsub(/ \* 10\^/,'e').gsub(/<font size="-2"> <\/font>/,','))
			end
		end
		
		@parser.command(e, 'list projects') do |c, params|
			channel = Channel.find_by_name e.recipient
			projects = channel.projects.map {|project| project.name }.join(', ')
			new_irc.msg e.recipient, "Projects currently announceing to #{channel.name}: #{projects}."
		end
		
		@parser.command(e, 'add project') do |c, params|
			project = Project.find_by_name c.message
			project = Project.create :name => c.message unless project
			channel = Channel.find_by_name e.recipient
			channel.project_subs.create :project => project
			new_irc.msg e.recipient, "Added #{project.name} to this channel."
		end
		
		@parser.command(e, 'add channel') do |c, params|
			channel = Channel.create :server => server, :name => c.message
			new_irc.join channel.name
			new_irc.msg e.recipient, "Joined #{channel.name}."
		end
		
		@parser.command(e, 'add server') do |c, params|
			params = c.message.split ' '
			server2 = Server.create :hostname => params[0]
			channel = server2.channels.create :name => params[1]
			add_network server2
			new_irc.msg e.recipient, "Connecting to #{server2.hostname}, and I'll join #{channel.name} once I'm there."
		end
		
		new_irc.msg e.recipient, "\001ACTION shoots #{e.sender.nick}\001" if e.message =~ /^\001ACTION evades the FBI(.*?)\001$/
		new_irc.msg e.recipient, "\001ACTION tastes crunchy\001" if e.message =~ /^\001ACTION eats FBI(.*?)\001$/
		new_irc.msg e.recipient, "\001ACTION dies\001" if e.message =~ /^\001ACTION kills FBI(.*?)\001$/
		new_irc.msg e.recipient, "\001ACTION hugs #{e.sender.nick}\001" if e.message =~ /^\001ACTION hugs FBI(.*?)\001$/
		new_irc.msg e.recipient, "ow" if e.message =~ /^\001ACTION kicks FBI(.*?)\001$/
		if e.message =~ /^\001ACTION rubs FBI-[0-9]+'s tummy(.*?)\001$/
			if rand(2) == 1
				new_irc.msg e.recipient, "\001ACTION bites #{e.sender.nick}'s hand\001"
			else
				new_irc.msg e.recipient, "*purr*"
			end
		end
	end
	
	Thread.new{ new_irc.connect }
end

Server.all.each do |server|
	add_network server
end

#~ add_network :freenode, 'irc.freenode.net', {
	#~ '#duxos' => ['dux'],
	#~ '#botters' => ['dux', 'fbi'],
	#~ '#duckinator' => ['dux'],
	#~ '#commits' => :none,
	#~ '##tsion' => :none,
	#~ '##mcgw' => :none,
#~ }
#~ 
#~ add_network :eighthbit, 'irc.eighthbit.net', {
	#~ '#bots' => ['archlinux-bot', 'CppBot', 'schemey', 'fbi', 'sonicbot', 'sonicIRC'],
	#~ '#commits' => :all,
	#~ '#dux' => ['dux'],
	#~ '#duckinator' => ['dux'],
	#~ '#programming' => ['schemey', 'dux', 'fbi']
#~ }

@receiver.run
