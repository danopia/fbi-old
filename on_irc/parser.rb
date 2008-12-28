class Parser
  class Command
    def initialize(message)
      @message = message
    end
    
    def message
      @message
    end
  end
  
  def command(e, name, admin_only = false)
    params = e.message.split
    @event = e
    if e.message =~ /^`#{name}(?: (.*))?/
      c = Parser::Command.new($1)
      if admin_only && is_admin?
        true
      elsif admin_only && !is_admin?
        false
      else
        true
      end
      yield c, params
    else
      false
    end
  end
  
  def is_admin?
    if @event.sender.nick == "chuck"
      true
    else
      false
    end
  end
end
