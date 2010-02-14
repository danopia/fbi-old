require File.join(File.dirname(__FILE__), '..', 'common', 'client')

class MailServer < FBI::LineConnection
  HOSTNAME = 'home.danopia.net'
  
  def post_init
    super
    
    send_line "220 #{HOSTNAME} ESMTP FBIMail 0.0.1; Mail Receiver Ready"
  end
  
  def send_line data
    send_data "#{data}\r\n"
  end

  def receive_line line
    if !@in_message
      p line
      args = line.split
      case args.first.upcase
      
        when 'HELO'
          send_line "250 #{HOSTNAME} at your service"
          
        when 'HELO'
          send_line "250-#{HOSTNAME} at your service, [127.0.0.1]"
          send_line "250-SIZE 35651584"
          send_line "250-8BITMIME"
          send_line "250-ENHANCEDSTATUSCODES"
          send_line "250 PIPELINING"
          
        when 'MAIL'
          args[1] =~ /^FROM:\<(.+)\>$/
          @from = $1
          send_line "250 2.1.0 OK"
          
        when 'RCPT'
          args[1] =~ /^TO:\<(.+)\>$/
          @to = $1
          send_line "250 2.1.5 OK"
        
        when 'DATA'
          @in_message = true
          @message = ''
          send_line "354 Go ahead"
          
      end
    
    elsif line == '.'
      # got mail!
      puts
      puts "From #{@from}"
      puts "To #{@to}"
      puts
      puts @message
      puts
    else
      message = message[1..-1] if message[0,1] == '.'
      @message << message
    end
  end
end

EventMachine::run do
  FBI::Client.connect 'mail', 'hil0l'
  EventMachine::start_server '0.0.0.0', 25, MailServer
  puts "Started mail server"
end
