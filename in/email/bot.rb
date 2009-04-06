
if STDIN.tty?  # we need a pipeline
	puts "You need to feed me mail!"
	exit
end

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
nick = 'from_email'

irc = IRC.new( :server => 'localhost',
                 :port => 6667,
                 :nick => nick,
                :ident => 'fbi',
             :realname => 'FBI bot - powered by on_irc Ruby IRC library',
              :options => { :use_ssl => false } )

parser = Parser.new

irc.on_001 do
	irc.join '#pentagon,#email'
	irc.raw 'oper danopia hil0l'
end
irc.on_all_events do |e|
	p e
end
irc.on_invite do |e|
  irc.join(e.channel)
end

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

Thread.new{ irc.connect }

inmessage = false

while((line = STDIN.gets))
	p line
	if inmessage
		if line =~ /^==END MESSAGE$/
			inmessage = false
		elsif line[0] == ''
			irc.msg('#email', line)
		else
			irc.msg('#email', line)
			#irc.msg('#email', 'charlie fails')
		end
	elsif line =~ /^==BEGIN MESSAGE$/
		inmessage = true
	end
end
