$LOAD_PATH << './../../on_irc'
puts "Loading IRC..."
require 'irc'
puts "Loading the IRC Parser..."
require 'parser'
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
nick = 'FBI-1'
inside_nick = 'to_IRC'

ircs = {
	:freenode => IRC.new( :server => 'irc.freenode.net',
		:port => 6667,
		:nick => nick,
		:ident => 'fbi',
		:realname => 'FBI bot - powered by on_irc Ruby IRC library',
		:options => { :use_ssl => false } ),

#	:dav7 => IRC.new( :server => 'irc.dav7.net',
#		:port => 6667,
#		:nick => nick,
#		:ident => 'fbi',
#		:realname => 'FBI bot - powered by on_irc Ruby IRC library',
#		:options => { :use_ssl => false } ),
		
	#:foonode => IRC.new( :server => '66.246.138.21',
	#	:port => 6667,
	#	:nick => nick,
	#	:ident => 'fbi',
	#	:realname => 'FBI bot - powered by on_irc Ruby IRC library',
	#	:options => { :use_ssl => false } )

}

irc = IRC.new( :server => 'localhost',
                 :port => 6667,
                 :nick => inside_nick,
                :ident => 'fbi',
             :realname => 'FBI bot - powered by on_irc Ruby IRC library',
              :options => { :use_ssl => false } )

parser = Parser.new


irc.on_all_events do |e|
	p e
end

irc.on_invite do |e|
	irc.join(e.channel)
end

#irc.on_join do |e|
#  irc.msg(e.channel, "Hey #{e.sender.nick}, and welcome to #{e.channel}!") if e.sender.nick != nick
#end

irc.on_privmsg do |e|
  
  parser.command(e, 'eval', true) do |c, params|
    begin
      irc.msg(e.recipient, eval(c.message, $b, 'eval', 1))
    rescue Exception => error
      irc.msg(e.recipient, 'compile error')
    end
  end
  
  parser.command(e, 'join') do |c, params|
    irc.join(c.message)
  end
  
  parser.command(e, 'size') do |c, params|
    irc.msg(e.recipient, c.message.size.to_s)
  end
  
  parser.command(e, 'calc') do |c, params|
    url = "http://www.google.com/search?q=#{ERB::Util.u(c.message)}"
    doc = Hpricot(open(url))
    calculation = (doc/'/html/body//#res/p/table/tr/td[3]/h2/font/b').inner_html
    if calculation.empty?
      irc.msg(e.recipient, 'Invalid Calculation.')
    else
      irc.msg(e.recipient, calculation.gsub(/&#215;/,'*').gsub(/<sup>/,'^').gsub(/<\/sup>/,'').gsub(/ \* 10\^/,'e').gsub(/<font size="-2"> <\/font>/,','))
    end
  end
  
  if e.message =~ /^\002(.*):\017 \00303(.*)\017 \00307(.*)\017 \00312(.*)\017 \00308(.*)\017 \00310(.*)\017 \00313(.*)\017 (.*)$/
  	irc.msg('#pentagon', "#{$2} commited revision #{$5} to #{$1}")
  	ircs[:dav7].msg('#commits', "#{$2} commited revision #{$5} to #{$1}")
  	#ircs[:foonode].msg('#commits', "#{$2} commited revision #{$5} to #{$1}")
  	if $1 == "failure"
  		irc.msg('#failure', "#{$2} commited revision #{$5}")
  	elsif $1 == "on_irc" or $1 == "fbi"
  		ircs[:dav7].msg('#faultlesssegment', "#{$2} commited revision #{$5} to #{$1}")
#  		ircs[:foonode].msg('#foonode', "#{$2} commited revision #{$5} to #{$1}")
  	end
  end
#  if e.message =~ /^Subject: (.*)$/
#  	ircs[:dav7].msg('#FaultlessSegment', "#{$1}")
#  end
  if e.sender.nick =~ /_in$/
  	#ircs[:dav7].msg('#FaultlessSegment', e.message)
  	#ircs[:foonode].msg('#FaultlessSegment', e.message)
  	ircs[:freenode].msg('#botters', e.message)
  end
  
  if e.message =~ /^\001ACTION eats #{nick}(.*?)\001$/
    irc.msg(e.recipient, "\001ACTION tastes crunchy\001")
  end
  if e.message =~ /^\001ACTION kills #{nick}(.*?)\001$/
    irc.msg(e.recipient, "\001ACTION dies\001")
  end
  if e.message =~ /^\001ACTION hugs #{nick}(.*?)\001$/
    irc.msg(e.recipient, "\001ACTION hugs #{e.sender.nick}\001")
  end
  if e.message =~ /^\001ACTION kicks #{nick}(.*?)\001$/
    irc.msg(e.recipient, "ow")
  end
  if e.message =~ /^\001ACTION rubs #{nick}'s tummy(.*?)\001$/
    irc.msg(e.recipient, "*purr*")
  end
end

irc.on_001 do
	irc.join '#pentagon,#cia,#failure,#email'
end
#ircs[:foonode].on_001 do
#	ircs[:foonode].join '#foonode,#commits'
#end
#ircs[:dav7].on_001 do
#	ircs[:dav7].join '#flood,#commits'
#end
ircs[:freenode].on_001 do
	ircs[:freenode].join '#botters,#commits,##tsion,##mcgw,#duckinator,#duxos'
end

ircs.each do |key, value|
	value.on_all_events do |e|
		p e
	end
	value.on_invite do |e|
		value.join(e.channel)
	end

	value.on_privmsg do |e|
		parser.command(e, 'calc') do |c, params|
			url = "http://www.google.com/search?q=#{ERB::Util.u(c.message)}"
			doc = Hpricot(open(url))
			calculation = (doc/'/html/body//#res/p/table/tr/td[3]/h2/font/b').inner_html
			if calculation.empty?
				value.msg(e.recipient, 'Invalid Calculation.')
			else
				value.msg(e.recipient, calculation.gsub(/&#215;/,'*').gsub(/<sup>/,'^').gsub(/<\/sup>/,'').gsub(/ \* 10\^/,'e').gsub(/<font size="-2"> <\/font>/,','))
			end
		end
  
		parser.command(e, 'size') do |c, params|
			value.msg(e.recipient, c.message.size.to_s)
		end
		
		if e.message =~ /^\001ACTION eats #{nick}(.*?)\001$/
			value.msg(e.recipient, "\001ACTION tastes crunchy\001")
		end
		if e.message =~ /^\001ACTION kills #{nick}(.*?)\001$/
			value.msg(e.recipient, "\001ACTION dies\001")
		end
		if e.message =~ /^\001ACTION hugs #{nick}(.*?)\001$/
			value.msg(e.recipient, "\001ACTION hugs #{e.sender.nick}\001")
		end
		if e.message =~ /^\001ACTION kicks #{nick}(.*?)\001$/
			value.msg(e.recipient, "ow")
		end
		value.msg(e.recipient, "*purr*") if e.message =~ /^\001ACTION rubs #{nick}'s tummy(.*?)\001$/
	end
	
	Thread.new{ value.connect }
end

#myhash.each do |key, value|

#Thread.new{ ircs[:freenode].connect }
#Thread.new{ ircs[:dav7].connect }
irc.connect
