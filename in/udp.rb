#$stdout.sync = true

require '../common/sender'

class UDPServer < EM::Protocols::LineAndTextProtocol
  def initialize
    @buffer = ''
  end

  def receive_data data
    @buffer += data
    while @buffer.include? "\n"
    	got_line @buffer.slice!(0, @buffer.index("\n")+1).chomp
    end
  rescue => e
    p e
  end
  
  def got_line line
    next unless line && line.size > 0
    
    data = JSON.parse line.gsub('\"', '"').gsub("\\\\", "\\")
    
    data['commits'].each do |commit|
      output = {
        :project => data['repository']['name'],
        :author => commit['author'],
        :branch => data['ref'].split('/').last,
        :commit => commit['id'],
        :message => commit['message'],
        :url => commit['url']
      }
      FBI::Sender.send 'commits', output
    end
  end
end

EventMachine::run do
  FBI::Sender::connect 'udp'
  EventMachine::open_datagram_socket '127.0.0.1', 1337, UDPServer
end