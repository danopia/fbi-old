require 'rubygems'
require 'eventmachine'
require 'socket'
require 'json'

module FBI
	class Client < EventMachine::Connection
		def self.connect *args
			EventMachine::connect "127.0.0.1", 5348, self, *args
		end
		def self.start_loop *args
			EventMachine::run { self.connect *args }
		end
		
		def initialize *args
			super
			begin
				@port, @ip = Socket.unpack_sockaddr_in get_peername
				puts "Connected to FBI at #{@ip}:#{@port}"
			rescue TypeError
				puts "Unable to determine endpoint (connection refused?)"
			end
			@args = args
			@buffer = ''
			@@instance = self
		end
		
		def receive_data data
			@buffer += data
			while @buffer.include? "\n"
				packet = @buffer.slice!(0, @buffer.index("\n")+1).chomp
				data = JSON.parse packet
				receive_object data
			end
		end
		
		def receive_object hash
		end
		
		def send_object hash
			send_data "#{hash.to_json}\n"
		end
		
		def unbind
			puts "Disconnected from FBI, reconnecting in 5 seconds"
			
   		EventMachine::add_timer 5 do # add_periodic_timer
   			EventMachine.next_tick { self.class.connect *@args }
				#timer.cancel if (n+=1) > 5
			end
		end
	end
end

#~ EventMachine::run do
  #~ EventMachine::connect "127.0.0.1", 5348, FBIClient
  #~ EventMachine::open_datagram_socket '127.0.0.1', 1337, UDPServer
  #~ EventMachine::add_periodic_timer( 10 ) { $stderr.write "*" }
#~ end
