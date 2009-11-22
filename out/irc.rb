$LOAD_PATH << './../../on_irc'
$LOAD_PATH << './../../on_irc/lib'
puts "Loading IRC..."
require 'lib/irc'
puts "Loading the IRC Parser..."
require 'lib/parser'
puts "Loading RubyGems..."
require 'rubygems'
#puts "Loading Activerecord..."
#require 'activerecord'
#puts "Loading models and connecting to database..."
#require 'models'
puts "Loading HPricot, OpenURI and ERB..."
require 'hpricot'
require 'open-uri'
require 'erb'

$b = binding()
$ircs = {}
$channels = {}
$parser = Parser.new

nick = 'to_irc'
irc = IRC.new( :server => 'localhost',
                 :port => 6667,
                 :nick => nick,
                :ident => 'fbi',
             :realname => 'FBI bot - powered by on_irc Ruby IRC library',
              :options => { :use_ssl => false } )

def process_message(project, message)
	$ircs.each do |name, irc|
		$channels[name].each do |channel, projects|
			irc.msg channel, "\002#{project}:\017 #{message}" if projects == :all || (projects.is_a?(Array) && projects.include?(project))
		end
	end
end

irc.on_all_events do |e|
	p e
end
irc.on_001 do
	irc.join '#pentagon,#cia'
end
irc.on_privmsg do |e|
  $parser.command(e, 'eval', true) do |c, params|
    begin
      irc.msg(e.recipient, eval(c.message, $b, 'eval', 1))
    rescue Exception => error
      irc.msg(e.recipient, 'compile error')
    end
  end
  
  irc.msg('#pentagon', "#{$2} commited revision #{$5} to #{$1}") if e.message =~ /^\002(.*):\017 \00303(.*)\017 \00307(.*)\017 \00312(.*)\017 \00308(.*)\017 \00310(.*)\017 \00313(.*)\017 (.*)$/
  process_message($1, $2) if e.sender.nick =~ /^from_/ && e.message =~ /^([^:]+): (.+)$/
  irc.msg(e.recipient, "\001ACTION pokes #{e.sender.nick}\001") if e.message =~ /^\001ACTION pokes to_irc(.*?)\001$/
  sleep 1
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
	$ircs[key] = new_irc
	$channels[key] = channels
	
	new_irc.on_all_events do |e|
		p e
	end
	new_irc.on_invite do |e|
		value.join(e.channel)
	end
	new_irc.on_001 do
		new_irc.msg 'NickServ', 'identify fbi hil0l'
		new_irc.join $channels[key].keys.join(',')
	end

	new_irc.on_privmsg do |e|
		$parser.command(e, 'calc') do |c, params|
			url = "http://www.google.com/search?q=#{ERB::Util.u(c.message)}"
			doc = Hpricot(open(url))
			calculation = (doc/'/html/body//#res/p/table/tr/td[3]/h2/font/b').inner_html
			if calculation.empty?
				new_irc.msg(e.recipient, 'Invalid Calculation.')
			else
				new_irc.msg(e.recipient, calculation.gsub(/&#215;/,'*').gsub(/<sup>/,'^').gsub(/<\/sup>/,'').gsub(/ \* 10\^/,'e').gsub(/<font size="-2"> <\/font>/,','))
			end
		end
  
		$parser.command(e, 'size') do |c, params|
			new_irc.msg(e.recipient, c.message.size.to_s)
		end
		
		new_irc.msg(e.recipient, "\001ACTION shoots #{e.sender.nick}\001") if e.message =~ /^\001ACTION evades the FBI(.*?)\001$/
		new_irc.msg(e.recipient, "\001ACTION tastes crunchy\001") if e.message =~ /^\001ACTION eats FBI(.*?)\001$/
		new_irc.msg(e.recipient, "\001ACTION dies\001") if e.message =~ /^\001ACTION kills FBI(.*?)\001$/
		new_irc.msg(e.recipient, "\001ACTION hugs #{e.sender.nick}\001") if e.message =~ /^\001ACTION hugs FBI(.*?)\001$/
		new_irc.msg(e.recipient, "ow") if e.message =~ /^\001ACTION kicks FBI(.*?)\001$/
		if e.message =~ /^\001ACTION rubs FBI-[0-9]+'s tummy(.*?)\001$/
			if rand(2) == 1
				new_irc.msg(e.recipient, "\001ACTION bites #{e.sender.nick}'s hand\001")
			else
				new_irc.msg(e.recipient, "*purr*")
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

#$ircs[:freenode].connect
irc.connect
