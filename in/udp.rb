require '../common/client'

class UDPServer < EM::Protocols::LineAndTextProtocol
  def initialize
    @buffer = ''
  end

  def receive_data data
    @buffer += data
    puts data
    while @buffer.include? "\n"
    	got_line @buffer.slice!(0, @buffer.index("\n")+1).chomp
    end
  end
  
  def got_line line
    next unless line && line.size > 0
    
    data = JSON.parse line # validate
		FBI::Client.publish 'commits', data
  end
end

EventMachine::run do
  FBI::Client.connect 'udp', 'hil0l'
  EventMachine::open_datagram_socket '127.0.0.1', 1337, UDPServer
end
