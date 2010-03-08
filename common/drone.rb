require File.join(File.dirname(__FILE__), 'connection')

module FBI
	class Drone < Connection
		attr_reader :master
		
		def self.connect master, args={}
      args[:host] ||= '127.0.0.1'
      args[:port] ||= 5348
			EventMachine::connect args[:host], args[:port], self, master
		end
		def self.start_loop *args
			EventMachine::run { self.connect *args }
		end
		
		def initialize master
			@master = master
		end
		
		def receive_object action, data
			@master.receive_object action, data
		end
	end
end