require File.join(File.dirname(__FILE__), '..', 'common', 'client')

require 'rubygems'
require 'net/dns/resolver'
require 'set'

class MailMessage
  attr_accessor :from, :to, :body, :remote
  
  def initialize from, to=nil, body=nil
    @from = from
    to = [to].compact unless to.is_a? Array
    @to = to
    @body = body
    @remote = false
  end
end

class MailSender < FBI::LineConnection
  def self.send message
    res = Net::DNS::Resolver.new
    
    # Set is amazing! And so fun/easy to abuse!
    targets = Set.new(message.to.map{|addr| addr.match(/^(.+)@(.+)$/).captures }).classify{|addr| addr[1] }
    targets.each_pair do |domain, addresses|
      exchanges = Set.new(res.mx(domain)).classify{|record| record.preference }.sort.last[1].map{|rec| rec.exchange }
      exchange = exchanges[rand(exchanges.size)]
      EventMachine.next_tick {
        EventMachine::connect exchange[0..-2].downcase, 25, MailSender, message, addresses.map{|addr| addr.join('@') }
      }
    end
  end
  
  def initialize message, addresses
    super()
    
    @message = message
    @addresses = addresses
    
    @state = :awaiting_welcome
  end
  
  def send_line data
    send_data "#{data}\r\n"
    puts "--> #{data}"
  end

  def receive_line line
    puts "<-- #{line}"
    
    numeric = line.match(/^[0-9]+/).to_s.to_i
    complete = !(line =~ /^[0-9]+\-/) # last resultant line?
    
    return unless complete
    
    case numeric
      when 354 # ready for data
        send_body
      when 250 # ok
        go_ahead
      when 220 # banner
        send_line "EHLO vps.danopia.net" #{MailServer.hostname}"
        @state = :said_hai
      when 221 # quit
        close_connection
      when 550 # bad recipient
    end
  end
  
  def go_ahead
    @state = case @state
      when :said_hai
        send_line "MAIL FROM:<#{@message.from}>"
        :sending_rcpts
        
      when :sending_rcpts
        if @addresses.any?
          send_line "RCPT TO:<#{@addresses.pop}>"
          :sending_rcpts
        else
          send_line 'DATA'
          :data
        end
        
      when :data
        send_line 'QUIT'
        :done
    end
  end
  
  def send_body
    @message.body.each_line do |line|
      line = ".#{line}" if line[0,1] == '.'
      send_line line.chomp
    end
    send_line '.'
  end
end

class MailServer < FBI::LineConnection
  @@hostname = `hostname`.chomp
  @@domains = [@@hostname]
  @@handler = nil
  
  def self.domains; @@domains; end
  
  def self.hostname= newname
    @@domains.delete @@hostname
    @@domains << newname
    @@hostname = newname
  end
  def self.hostname
    @@hostname
  end
  
  def self.on_message &blck
    @@handler = blck
  end
  
  
  def initialize relay=false
    super()
    
    send_line "220 #{@@hostname} ESMTP FBIMail 0.0.1; Mail #{relay ? 'Relay' : 'Receiver'} Ready"
    @message = nil
    @relay = relay
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
          send_line "250 #{@@hostname} at your service"
          
        when 'EHLO'
          send_line "250-#{@@hostname} at your service"
          send_line "250-SIZE 35651584" # heh? got this from google
          send_line "250-8BITMIME"
          send_line "250-ENHANCEDSTATUSCODES"
          send_line "250 PIPELINING"
          
        when 'MAIL'
          args[1] =~ /^FROM:\<(.+)\>$/i
          @message = MailMessage.new($1 || args[2][1..-2])
          @message.remote = true unless @@domains.include? @message.from.split('@').last
          send_line "250 2.1.0 OK"
          
        when 'RCPT'
          args[1] =~ /^TO:\<(.+)\>$/i
          addr = $1 || args[2][1..-2]
          if @@domains.include? addr.split('@').last
            send_line "250 2.1.5 OK"
            @message.to << addr
          elsif @relay
            send_line "250 2.1.5 OK"
            @message.to << addr
            @message.remote ||= true
          else # don't want to be marked as an open relay
            send_line "550 5.1.1 The email account that you tried to reach does not exist."
          end
        
        when 'DATA'
          @in_message = true
          @message.body = ''
          send_line "354  Go ahead"
          
        when 'QUIT'
          send_line "221 2.0.0 #{@@hostname} closing connection"
          close_connection
      end
    elsif line == '.'
      @in_message = false
      handle_message
      send_line '250 2.0.0 OK'
    else
      line = line[1..-1] if line[0,1] == '.'
      @message.body << line + "\n"
    end
  end
  
  def handle_message
    if @@handler && @@handler.call(@message)
      @message = nil
      return
    end

    if @message.remote && @relay
      MailSender.send @message
    end
    
    @message = nil
  end
end

fbi = FBI::Client.new 'mail', 'hil0l'

EventMachine::next_tick do
  smtp = EventMachine::start_server '0.0.0.0', 25, MailServer
  submission = EventMachine::start_server '127.0.0.1', 587, MailServer, true
  MailServer.domains << 'fbi.danopia.net' # accept mail to this domain
  
  MailServer.on_message do |message|
    #File.open('mail.txt', 'w') {|f| f.puts @message }
    if message.body.include?('Log Message:') && message.from.include?('sourceforge.net')
      
      message.body =~ /^Revision: ([0-9]+)$/
      rev = $1.to_i
      
      message.body =~ /(http:\/\/.+\.sourceforge\.net\/(.+)\/\?rev=[0-9]+&view=rev)/
      url, project = $1, $2
      
      message.body =~ /^Author: +(.+)$/
      author = $1
      
      message.body =~ /^Subject: SF.net .+: .+:\[[0-9]+\] +(.+)$/
      path = $1
      
      index = message.body.index("Log Message:") + 20
      index = message.body.index("\n", index) + 1
      end_index = message.body.index("\n\nModified Paths:") - 1
      log = message.body[index..end_index]
      
      fbi.publish 'commits', [{
        :project => project,
        :owner => nil,
        :fork => false,
        :author => {:email => "#{author}@users.sourceforge.net", :name => author},
        :branch => path,
        :commit => "r#{rev}",
        :message => log,
        :url => url,
      }]
    elsif message.from.include?('@lists.launchpad.net')
      
      message.body =~ /^From: (.+) <([^>]+)>$/
      author = {:name => $1, :email => $2}
      
      message.body.gsub("\n    ", ' ') =~ /^Subject: (.+)$/
      subject = $1
      subject.gsub!('  ', ' ') while subject.include?('  ')
      
      message.body =~ /^List-Id: <([^>]+)>$/
      list = $1
      
      message.body =~ /^List-Archive: <([^>]+)>$/
      archive = $1
      
      project = case list
        when 'ooc-dev.lists.launchpad.net'; 'ooc'
        else; nil
      end
      
      return unless project
      fbi.publish 'mailinglist', [{
        :list => list,
        :author => author,
        :subject => subject,
        :url => archive,
        :project => project,
      }]
    else
      next false
    end
    true
  end
  
  puts "Started mail server"
end

fbi.connect
EventMachine.run {} if $0 == __FILE__
