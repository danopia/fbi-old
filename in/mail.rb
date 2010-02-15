require File.join(File.dirname(__FILE__), '..', 'common', 'client')

class MailServer < FBI::LineConnection
  attr_accessor :hostname
  
  def post_init hostname=nil
    super
    @hostname = hostname || `hostname`.chomp
    send_line "220 #{@hostname} ESMTP FBIMail 0.0.1; Mail Receiver Ready"
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
          send_line "250 #{hostname} at your service"
          
        when 'EHLO'
          send_line "250-#{hostname} at your service"
          send_line "250-SIZE 35651584" # heh? got this from google
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
          if @to.include? hostname
            send_line "250 2.1.5 OK"
          else # don't want to be marked as an open relay
            send_line "550 5.1.1 The email account that you tried to reach does not exist."
          end
        
        when 'DATA'
          @in_message = true
          @message = ''
          send_line "354  Go ahead"
          
        when 'QUIT'
          send_line "221 2.0.0 #{hostname} closing connection"
          close_connection
      end
    elsif line == '.'
      @in_message = false
      got_mail
      send_line '250 2.0.0 OK'
    else
      line = line[1..-1] if line[0,1] == '.'
      @message += line + "\n"
    end
  end
  
  def got_mail
    #File.open('mail.txt', 'w') {|f| f.puts @message }
    if @message.include?('Log Message:') && @from.include?('sourceforge.net')
      
      @message =~ /^Revision: ([0-9]+)$/
      rev = $1.to_i
      
      @message =~ /(http:\/\/.+\.sourceforge\.net\/(.+)\/\?rev=[0-9]+&view=rev)/
      url, project = $1, $2
      
      @message =~ /^Author: +(.+)$/
      author = $1
      
      @message =~ /^Subject: SF.net .+: .+:\[[0-9]+\] +(.+)$/
      path = $1
      
      index = @message.index("Log Message:") + 20
      index = @message.index("\n", index) + 1
      end_index = @message.index("\n\nModified Paths:") - 1
      message = @message[index..end_index]
      
      FBI::Client.publish 'commits', [{
        :project => project,
        :owner => nil,
        :fork => false,
        :author => {:email => nil, :name => author},
        :branch => path,
        :commit => "r#{rev}",
        :message => message,
        :url => url,
      }]
    end
  end
end

EventMachine::run do
  FBI::Client.connect 'mail', 'hil0l'
  EventMachine::start_server '0.0.0.0', 25, MailServer
  puts "Started mail server"
end
