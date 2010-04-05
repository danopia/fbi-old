module FBI_IRC

class EventContext
	attr_reader :conn, :event, :origin, :target, :params, :network, :manager
	
	def initialize conn, event, origin, target, params
		@conn = conn
		@event = event
		@origin = origin
		@target = target
		@params = params
    
    @network = @conn.network
    @manager = @network.manager
	end
	
	def param
		@params.join ' '
	end
  
  def [] index
    @params[index]
  end
	
	def pm?
		@conn.nick == @target
	end
	def channel?
		@conn.nick != @target
	end
  
  def reply_to
		pm? ? @origin : @target
  end
	
	def ctcp?
		@event == :ctcp || @event == :ctcp_reply
	end
	
	def admin?
		@manager.admin? @origin
	end
	
	def message message
		@conn.message reply_to, message
	end
	def notice message
		@conn.notice reply_to, message
	end
	def action message
		@conn.action reply_to, message
	end
	
	def respond message
		if ctcp?
			raise StandardError, 'cannot respond to a CTCP response' if @event == :notice
			@conn.ctcp_reply @origin, @params.first, message
			return
		end
		
		message = pm? ? message : "#{origin[:nick]}: #{message}"
		
		if @event == :notice
			notice message
		else
			message message
		end
	end
	
end # event_context class

end # module
