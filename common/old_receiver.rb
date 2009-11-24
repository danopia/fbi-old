$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'on_irc')
require File.join(File.dirname(__FILE__), '..', 'on_irc', 'irc')
require File.join(File.dirname(__FILE__), '..', 'on_irc', 'parser')
#require 'rubygems'"
#require 'activerecord'
#require 'models'

class Receiver
	attr_reader :nick, :irc
	
	def initialize(target)
		@parser = Parser.new
		@nick = "to_#{target}"
		
		@irc = IRC.new( :server => 'localhost',
											:port => 6667,
											:nick => @nick,
										 :ident => 'fbi',
									:realname => 'FBI bot - powered by on_irc Ruby IRC library',
									 :options => { :use_ssl => false } )
		
		@irc.on_001 do
			@irc.join '#pentagon'
		end
		
		@irc.on_privmsg do |e|
			@on_message.call $1, $2 if e.sender.nick =~ /^from_/ && e.message =~ /^([^:]+): (.+)$/
			@irc.msg(e.recipient, "\001ACTION pokes #{e.sender.nick}\001") if e.message =~ /^\001ACTION pokes #{nick}(.*?)\001$/
		end
	end
	
	def on_message &blck
		@on_message = blck
	end
	
	def run
		@irc.connect
	end
end
