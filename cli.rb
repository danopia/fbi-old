require File.join(File.dirname(__FILE__), 'common', 'client')

client = FBI::Client.new 'cli', 'hil0l'

#~ print 'Username: '
#~ STDOUT.flush
#~ client.name = gets.chomp
#~ 
#~ print 'Password: '
#~ STDOUT.flush
#~ client.secret = gets.chomp

Thread.new { begin; client.start_loop; rescue => ex; puts ex,ex.message,ex.backtrace; end }

while true
  action = gets.chomp
  next if action.size == 0
  
  case action
    when 'subscribe', 'join', 'sub'
      client.send_object 'subscribe', :channels => gets.chomp.split
      
    when 'unsubscribe', 'leave', 'part', 'unsub'
      client.send_object 'unsubscribe', :channels => gets.chomp.split
      
    when 'publish', 'send'
      client.send_object 'publish', :target => gets.chomp, :data => JSON.parse(gets)
    
    when 'disconnect', 'channels', 'subscriptions', 'components'
      client.send_object action, {}
    
    when 'dblist'
      client.send '#db', :method => 'select', :table => 'users'
      
    when 'dbins'
      client.send '#db', :method => 'insert', :table => 'users', :record => 
        {:username => 'danopia', :email => 'test@danopia.net', :password_hash => '', :salt => '', :created_at => Time.now}
    
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
