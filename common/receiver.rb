require 'rubygems'
require 'eventmachine'
require 'socket'

class FBIClient < EM::Protocols::LineAndTextProtocol
	def self.on_packet &blck
		@@handler = blck
	end
	
	def self.connect
		EventMachine::connect "127.0.0.1", 5348, FBIClient
	end
	
	
	def initialize
    @port, @ip = Socket.unpack_sockaddr_in get_peername
    puts "connected to #{@ip}:#{@port}"
    @buffer = ''
    @lbp_mode = :lines
    @@instance = self
	end
	
  def receive_data data
    @buffer += data
    while @buffer.include? "\n"
    	got_line @buffer.slice!(0, @buffer.index("\n")+1).chomp
    end
  end
  
  def got_line line
  	@@handler.call line if @@handler
  end
	
	def unbind
		puts "Disconnected from FBI"
	end
end

#~ EventMachine::run do
  #~ EventMachine::connect "127.0.0.1", 5348, FBIClient
  #~ EventMachine::open_datagram_socket '127.0.0.1', 1337, UDPServer
  #~ #EventMachine::add_periodic_timer( 10 ) { $stderr.write "*" }
#~ end
