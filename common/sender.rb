require File.join(File.dirname(__FILE__), 'client')

module FBI
	class Sender < Client
		def self.send channel, data
			@@instance.send_object({'channel' => channel, 'data' => data})
		end
		
		def initialize user=nil
			super user
			login(user) if user
		end
		
		def login user
			send_object({
				'auth' => true,
				'user' => user
			})
		end
	end
end
