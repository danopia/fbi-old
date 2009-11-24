require 'rubygems'
require 'eventmachine'
require 'socket'

class FBIServer < EM::Protocols::LineAndTextProtocol
	INSTANCES = []
	
  def initialize
    @port, @ip = Socket.unpack_sockaddr_in get_peername
    puts "connection from #{@ip}:#{@port}"
    @buffer = ''
    @sender = false
    
    INSTANCES << self
  end

  def receive_data data
    @buffer += data
    while @buffer.include? "\n"
    	got_line @buffer.slice!(0, @buffer.index("\n")+1).chomp
    end
  end
  
  def got_line line
  	if line.index('sender ') == 0
  		@sender = line.split(' ', 2).last
    	puts "#{@ip}:#{@port} asked to be a sender, as #{@sender}"
  	elsif @sender
			puts "#{@sender}: #{line}"
			INSTANCES.each do |conn|
				conn.send_data "#{line}\n"
			end
		end
  end
  
  def unbind
  	puts "connection closed from #{@ip}:#{@port}"
  	INSTANCES.delete self
  end
end

EventMachine::run do
  EventMachine::start_server "127.0.0.1", 5348, FBIServer
end
