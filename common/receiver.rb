require File.join(File.dirname(__FILE__), 'client')

module FBI
	class Receiver < Client
		def self.on_object &blck
			@@handler = blck
		end
		
		def initialize *channels
			super *channels
			subscribe_to channels if channels.any?
		end
		
		def subscribe_to channels
			send_object({
				'subscribe' => true,
				'feeds' => channels
			})
		end
		
		def receive_object hash
			@@handler.call hash['channel'], hash['data'] if @@handler && hash.has_key?('data')
		end
	end
end
