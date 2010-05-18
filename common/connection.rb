require File.join(File.dirname(__FILE__), 'lineconnection')

$stdout.sync = true

require 'json'

module FBI
class Connection < LineConnection
  attr_accessor :name, :account, :secret, :args
  
  def initialize name=nil, account=nil, secret=nil, *args
    super() # init @buffer
    
    @name     = name
    @account  = account
    @secret   = secret
    @args     = args
  end
	
  def post_init
    login if @account && respond_to?(:login)
    startup *@args if respond_to? :startup
    
    super # grab IP
  end
		
  def send_object action, origin, target, payload={}
    hash['action'] = action
    send_line({
      :action => action,
      :origin => origin,
      :target => target,
      :payload => payload,
    }.to_json)
  end

  def receive_line line
    hash = JSON.parse line
    receive_object hash['action'], hash['origin'], hash['target'], hash['payload']
 
  rescue JSON::ParserError => ex
    puts "Error parsing JSON: #{ex.message}"
  end
  
  def receive_object action, origin, target, payload
  end
  
  def unbind
    super # log to console
  end
end # class
end # module
