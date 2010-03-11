require File.join(File.dirname(__FILE__), 'connection')

module FBI
	class Drone < Connection
		attr_reader :master
		
		def self.connect master, args={}
      args[:host] ||= 'danopia.net'
      args[:port] ||= 5348
			EventMachine::connect args[:host], args[:port], self, master
		end
		
		def initialize master
      super()
			@master = master
		end
    
    def startup *args
      @master.startup self, *args
    end
		
		def receive_object action, data
			@master.receive_object action, data
		end
	end
end
