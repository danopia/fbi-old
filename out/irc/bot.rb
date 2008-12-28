$LOAD_PATH << './../../on_irc'
puts "Loading IRC..."
require 'irc'
puts "Loading the IRC Parser..."
require 'parser'
puts "Loading RubyGems..."
require 'rubygems'
puts "Loading Activerecord..."
require 'activerecord'
puts "Loading models and connecting to database..."
require 'models'
puts "Loading HPricot, OpenURI and ERB..."
require 'hpricot'
require 'open-uri'
require 'erb'

$b = binding()
nick = 'FBI-1'

ircs = {
	:freenode => IRC.new( :server => 'irc.freenode.org',
		:port => 6667,
		:nick => 'FBI-1',
		:ident => 'fbi',
		:realname => 'FBI bot - powered by on_irc Ruby IRC library',
		:options => { :use_ssl => false } ),

	:dav7 => IRC.new( :server => 'irc.dav7.net',
		:port => 6667,
		:nick => 'FBI-1',
		:ident => 'fbi',
		:realname => 'FBI bot - powered by on_irc Ruby IRC library',
		:options => { :use_ssl => false } )

}

irc = IRC.new( :server => 'localhost',
                 :port => 6667,
                 :nick => 'FBI}IRC',
                :ident => 'fbi',
             :realname => 'FBI bot - powered by on_irc Ruby IRC library',
              :options => { :use_ssl => false } )

parser = Parser.new

ircs[:freenode].on_001 do
	ircs[:freenode].join '#botters,#commits,##tsion'
end
ircs[:dav7].on_001 do
	ircs[:dav7].join '#commits'
end
irc.on_001 do
	irc.join '#pentagon,#cia,#failure,#email'
end

ircs[:freenode].on_all_events do |e|
	p e
end
ircs[:dav7].on_all_events do |e|
	p e
end
irc.on_all_events do |e|
	p e
end

ircs[:freenode].on_invite do |e|
  ircs[:freenode].join(e.channel)
end
ircs[:dav7].on_invite do |e|
  ircs[:dav7].join(e.channel)
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
  	if $1 == "failure"
  		irc.msg('#failure', "#{$2} commited revision #{$5}")
  	end
  end
  if e.message =~ /^Subject: (.*)$/
  	ircs[:dav7].msg('#FaultlessSegment', "#{$1}")
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

ircs[:dav7].on_privmsg do |e|
  parser.command(e, 'calc') do |c, params|
    url = "http://www.google.com/search?q=#{ERB::Util.u(c.message)}"
    doc = Hpricot(open(url))
    calculation = (doc/'/html/body//#res/p/table/tr/td[3]/h2/font/b').inner_html
    if calculation.empty?
      ircs[:dav7].msg(e.recipient, 'Invalid Calculation.')
    else
      ircs[:dav7].msg(e.recipient, calculation.gsub(/&#215;/,'*').gsub(/<sup>/,'^').gsub(/<\/sup>/,'').gsub(/ \* 10\^/,'e').gsub(/<font size="-2"> <\/font>/,','))
    end
  end
  
  if e.message =~ /^\001ACTION eats #{nick}(.*?)\001$/
    ircs[:dav7].msg(e.recipient, "\001ACTION tastes crunchy\001")
  end
  if e.message =~ /^\001ACTION kills #{nick}(.*?)\001$/
    ircs[:dav7].msg(e.recipient, "\001ACTION dies\001")
  end
  if e.message =~ /^\001ACTION hugs #{nick}(.*?)\001$/
    ircs[:dav7].msg(e.recipient, "\001ACTION hugs #{e.sender.nick}\001")
  end
  if e.message =~ /^\001ACTION kicks #{nick}(.*?)\001$/
    ircs[:dav7].msg(e.recipient, "ow")
  end
  if e.message =~ /^\001ACTION rubs #{nick}'s tummy(.*?)\001$/
    ircs[:dav7].msg(e.recipient, "*purr*")
  end
end

#myhash.each do |key, value|

#Thread.new{ ircs[:freenode].connect }
Thread.new{ ircs[:dav7].connect }
irc.connect
