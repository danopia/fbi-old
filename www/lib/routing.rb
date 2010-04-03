class Routing
  attr_reader :routes, :base, :regexp
  
  def initialize base='', &blck
    base = base.source if base.is_a? Regexp
    @base = base
    @regexp = Regexp.new "^#{@base}"
    
    @routes = []
    
    setup &blck if blck
  end
  
  def add_route *args
    regex = args.shift
    regex = regex.source if regex.is_a? Regexp
    regex = "#{@base}#{regex}"
    
    @routes << Route.new(regex, *args)
  end
  
  def find path
    @routes.map {|route| route.find path}.compact.first if @regexp =~ path
  end
  
  def setup &blck
    dsl = RoutingDSL.new self
    dsl.instance_eval &blck
    self
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
    path = @routing.base + path if path.is_a? String
    path = path.source if path.is_a? Regexp
    
    route = Routing.new path, &blck
    @routing.routes << route
    route
  end
end
