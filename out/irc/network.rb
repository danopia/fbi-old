module FBI_IRC

class Network
	attr_reader :manager, :record, :connections, :next_id, :max_chans
	
	def initialize manager, record={}
		@manager = manager
		@record = record
		
		@connections = []
		@next_id = 1
		@max_chans = 20
		
		record.channels.each {|channel| join channel }
	end
	
	def join channel
		conn = @connections.find do |conn|
			conn.channels.size < @max_chans
		end
		
		conn ||= spawn_connection
		conn && conn.join(channel)
	end
	
	def quit message=nil
		@connections.each {|conn| conn.quit message }
		@connections.clear
	end
	
	def next_id!
		(@next_id += 1) - 1
	end
	
	def spawn_connection
		EventMachine::connect @record.hostname, @record.port, Connection, self
	rescue EventMachine::ConnectionError => ex
		puts "Error while connecting to IRC server #{@record.slug}: #{ex.message}"
		nil
	end
	
	def remove_conn conn
		@manager.channels.delete_if {|id, chan| chan.connection == conn }
		@connections.delete conn
	end
end # network class

end # module
