$LOAD_PATH << './../common'
require 'receiver'
#require 'rubygems'
#require 'activerecord'
#require 'models'

@ircs = {}
@channels = {}
@parser = Parser.new
@receiver = Receiver.new 'irc'

@receiver.on_message do |project, message|
	@ircs.each do |name, irc|
		@channels[name].each do |channel, projects|
			if projects == :all || (projects.is_a?(Array) && projects.include?(project))
				irc.msg channel, "\002#{project}:\017 #{message}"
  			sleep 1
  		end
		end
	end
end

def add_network(key, server, channels = {}, port=6667)
	new_irc = IRC.new(
		:server => server,
		:port => port,
		:nick => 'FBI-1',
		:ident => 'fbi',
		:realname => 'FBI bot - powered by on_irc Ruby IRC library',
		:options => { :use_ssl => false }
	)
	@ircs[key] = new_irc
	@channels[key] = channels
	
	new_irc.on_all_events do |e|
		#p e
	end
	new_irc.on_invite do |e|
		value.join e.channel
	end
	new_irc.on_001 do
		new_irc.msg 'NickServ', 'identify fbi hil0l'
		new_irc.join @channels[key].keys.join(',')
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

add_network :freenode, 'irc.freenode.net', {
	'#duxos' => ['dux'],
	'#botters' => ['dux', 'fbi'],
	'#duckinator' => ['dux'],
	'#commits' => :all,
	'##tsion' => :none,
	'##mcgw' => :none,
}

add_network :eighthbit, 'irc.eighthbit.net', {
	'#bots' => ['archlinux-bot', 'CppBot', 'schemey', 'fbi'],
	'#commits' => :all,
	'#dux' => ['dux'],
	'#duckinator' => ['dux'],
	'#programming' => ['schemey', 'dux', 'fbi']
}

@receiver.run
