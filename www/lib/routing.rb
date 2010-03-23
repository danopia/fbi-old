class Routing
  attr_reader :routes
  
  def initialize
    @routes = []
  end
  
  def add_route *args
    @routes << Route.new(*args)
  end
  
  def find path
    @routes.map {|route| route.find path}.compact.first
  end
  
  def setup &blck
    dsl = RoutingDSL.new self
    dsl.instance_eval &blck
    self
  end
end

class SubRouting
  attr_reader :base, :regexp, :routes
  
  def initialize base
    base = base.source if base.is_a? Regexp
    
    @base = base
    @regexp = Regexp.new "^#{@base}"
    @routes = []
  end
  
  def add_route *args
    regex = args.shift
    regex = regex.source if regex.is_a? Regexp
    regex = "#{@base}#{regex}"
    
    @routes << Route.new(regex, *args)
  end
  
  def find path
    return nil unless @regexp =~ path
    @routes.map {|route| route.find path}.compact.first
  end
end

class Route
  attr_accessor :pattern, :klass, :method
  attr_reader :params
  
  def initialize pattern, klass, method, params={}
    pattern = Regexp.new("^#{pattern}") unless pattern.is_a? Regexp
    
    @pattern = pattern
    @klass = klass.to_s
    @method = method.to_sym
    @params = params
  end
  
  def =~ path
    @pattern =~ path
  end
  
  def find path
    @pattern =~ path && self
  end
  
  def handle path, env
    match = @pattern.match(path)
    
    controller = alloc_controller
    controller.action = @method
    controller.env = env
    controller.__send__ @method, match.captures, @params, env
    controller.render
  rescue => ex
    puts ex, ex.message, ex.backtrace
  end
  
  def alloc_controller
    load self.filename
    @controller = self.controller_class.new
  end
  
  def filename
    File.join(File.dirname(__FILE__), '..', 'controllers', @klass.downcase + '.rb')
  end
  
  def controller_name
    @klass.capitalize + 'Controller'
  end
  
  def controller_class
    Class.const_get(controller_name)
  end
end

class RoutingDSL
  attr_reader :routing
  
  def initialize routing
    @routing = routing
  end
  
  def connect *args
    @routing.add_route *args
  end
  
  def sub_route path, &blck
    path = "^#{path}" unless path.is_a? String
    path = path.source if path.is_a? Regexp
    
    route = SubRouting.new path
    @routing.routes << route
    dsl = RoutingDSL.new route
    dsl.instance_eval &blck
    route
  end
end
