require File.join(File.dirname(__FILE__), 'lineconnection')

$stdout.sync = true

require 'json'

module FBI
class Connection < LineConnection
	attr_accessor :username, :secret, :args, :port, :ip
	INSTANCES = []
	
	def initialize username=nil, secret=nil, *args
		super()
		
		@username		= username
		@secret			= secret
		@args				= args
		
		@@instance	= self
    INSTANCES << self
  end
	
  def post_init
		login if @username
		startup *@args if respond_to? :startup
		
		super
  end
		
	def send_object action, hash
		hash['action'] = action
		send_line hash.to_json
	end

  def receive_line line
		hash = JSON.parse line
		receive_object hash['action'], hash
 
  rescue JSON::ParserError => ex
    puts "Error parsing JSON: #{ex.message}"
  end
  
  def receive_object action, data
  end
  
  def unbind
  	super
  	INSTANCES.delete self
  end
end # class
end # module
