$stdout.sync = true

require 'rubygems'
require 'eventmachine'
require 'socket'
require 'json'

module FBI
class Connection < EventMachine::Connection
	attr_accessor :username, :secret, :args, :port, :ip
	INSTANCES = []
	
	def initialize username=nil, secret=nil, *args
		super()
		
		@username		= username
		@secret			= secret
		@args				= args
		@buffer			= ''
		
		@@instance	= self
    INSTANCES << self
  end
	
  def post_init
		login if @username
		startup *@args if respond_to? :startup
    
    sleep 0.25
    @port, @ip = Socket.unpack_sockaddr_in get_peername
    puts "Connected to #{@ip}:#{@port}"
  end
		
	def send_object action, hash
		hash['action'] = action
		send_data "#{hash.to_json}\n"
	end

  def receive_data data
    @buffer += data
    while @buffer.include? "\n"
    	line = @buffer.slice!(0, @buffer.index("\n")+1).chomp
    	hash = JSON.parse line
    	receive_object hash['action'], hash
    end
  end
  
  def receive_object action, data
  end
		
	def login
		send_object 'auth', {
			'user'		=> @username,
			'secret'	=> @secret
		}
	end
  
  def unbind
  	puts "connection closed to #{@ip}:#{@port}"
  	INSTANCES.delete self
  end
end # class
end # module
