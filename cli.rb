require File.join(File.dirname(__FILE__), 'common', 'client')

client = FBI::Client.new 'cli', 'hil0l'

#~ print 'Username: '
#~ STDOUT.flush
#~ client.name = gets.chomp
#~ 
#~ print 'Password: '
#~ STDOUT.flush
#~ client.secret = gets.chomp

Thread.new { client.start_loop }

while true
  action = gets.chomp
  next unless action.any?
  
  case action
    when 'subscribe', 'join'
      client.send_object 'subscribe', :channels => gets.chomp.split
      
    when 'publish', 'send'
      client.send_object 'publish', :target => gets.chomp, :data => JSON.parse(gets)
    
    else
      print "JSON for #{action} (or nothing): "
      STDOUT.flush
      json = gets.chomp
      
      if json.any?
        data = JSON.parse json
      else
        data = {}
        while true
          line = gets.chomp
          break unless line.any?
          
          parts = line.split ': ', 2
          data[parts[0]] = parts[1]
        end
      end
      
      client.send_object action, data
  
  end
end
