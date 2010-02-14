require File.join(File.dirname(__FILE__), '..', 'common', 'client')

class MailServer < FBI::LineConnection
  HOSTNAME = 'vps.danopia.net'
  
  def post_init
    super
    
    send_line "220 #{HOSTNAME} ESMTP FBIMail 0.0.1; Mail Receiver Ready"
  end
  
  def send_line data
    send_data "#{data}\r\n"
    puts "--> #{data}"
  end

  def receive_line line
    puts "<-- #{line}"
    
    if !@in_message
      args = line.split
      case args.first.upcase
      
        when 'HELO'
          send_line "250 #{HOSTNAME} at your service"
          
        when 'EHLO'
          send_line "250-#{HOSTNAME} at your service, [127.0.0.1]"
          send_line "250-SIZE 35651584"
          send_line "250-8BITMIME"
          send_line "250-ENHANCEDSTATUSCODES"
          send_line "250 PIPELINING"
          
        when 'MAIL'
          args[1] =~ /^FROM:\<(.+)\>$/i
          @from = $1
          send_line "250 2.1.0 OK"
          
        when 'RCPT'
          args[1] =~ /^TO:\<(.+)\>$/i
          @to = $1 || args[2][1..-2]
          if @to.include? HOSTNAME
            send_line "250 2.1.5 OK"
          else
            puts 'FAIL'
          end
        
        when 'DATA'
          @in_message = true
          @message = ''
          send_line "354 Go ahead"
          
        when 'QUIT'
          send_line "221 #{HOSTNAME} Service closing transmission channel"
          close_connection
          
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
