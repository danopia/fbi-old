$LOAD_PATH << './../../on_irc'
$LOAD_PATH << './../../on_irc/lib'
puts "Loading IRC..."
require 'lib/irc'
puts "Loading the IRC Parser..."
require 'lib/parser'

$b = binding()
nick = 'from_udp'

irc = IRC.new( :server => 'localhost',
                 :port => 6667,
                 :nick => nick,
                :ident => 'fbi',
             :realname => 'FBI bot - powered by on_irc Ruby IRC library',
              :options => { :use_ssl => false } )

parser = Parser.new

irc.on_001 do
	irc.join '#pentagon'
	irc.raw 'oper danopia hil0l'
end
irc.on_all_events do |e|
	#p e
end
irc.on_invite do |e|
  irc.join(e.channel)
end

Thread.new{ irc.connect }

require 'socket'
require 'ipaddr'

require 'rubygems'
require 'json'

require 'open-uri'

sock = UDPSocket.new
sock.bind(Socket::INADDR_ANY, 1337)

loop do
  msg = sock.recvfrom(10_000)[0]
  next unless msg && msg.size > 0
  
  begin
    json = JSON.parse msg.gsub('\"', '"').gsub("\\\\", "\\")
    
    json['commits'].each do |commit|
      url = open('http://is.gd/api.php?longurl=' + commit['url']).read
      
      #\002(.*):\017 \00303(.*)\017 \00307(.*)\017 \00312(.*)\017 \00308(.*)\017 \00310(.*)\017 \00313(.*)\017 
      msg = "#{json['repository']['name']}: \00303#{commit['author']['name']} \00307#{json['ref'].split('/').last}\017 \002#{commit['id'][0,8]}\017: #{commit['message']} \00302<\002\002#{url}>"
      #msg = "#{json['repository']['name']}: #{commit['author']['name']} #{json['ref'].split('/').last} #{commit['id'][0,8]} : #{commit['message']} <\002\002#{commit['url']}>"
    
      irc.msg '#pentagon', msg
    end
  #rescue JSON::ParserError
   # puts "JSON error"
  end
end
