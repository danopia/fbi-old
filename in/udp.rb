require File.join(File.dirname(__FILE__), '..', 'common', 'client')

class UDPServer < FBI::LineConnection
  # prevent LineConnection from grabbing an IP
  def post_init; end

  def receive_line line
		FBI::Client.publish 'commits', JSON.parse(line)
  rescue JSON::ParserError => ex
    puts "Error parsing JSON: #{ex.message}"
  end
end

EventMachine::run do
  FBI::Client.connect 'udp', 'hil0l'
  EventMachine::open_datagram_socket '127.0.0.1', 1337, UDPServer
end
