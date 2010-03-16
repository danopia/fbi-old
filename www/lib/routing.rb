class Routing
  attr_reader :routes
  
  def initialize
    @routes = []
  end
  
  def add_route *args
    @routes << Route.new(*args)
  end
  
  def find path
    @routes.find {|route| route =~ path }
  end
  
  def setup &blck
    dsl = RoutingDSL.new self
    dsl.instance_eval &blck
    self
  end
end

class RoutingDSL
  attr_reader :routing
  
  def initialize routing
    @routing = routing
  end
  
  def connect *args
    unless args[0].is_a? Regexp
      args[0] = Regexp.new("^#{args[0]}") 
    end
    
    @routing.routes << Route.new(*args)
  end
end

class Route
  attr_accessor :pattern, :klass, :method
  attr_reader :params
  
  def initialize pattern, klass, method, params={}
    @pattern = pattern
    @klass = klass.to_s
    @method = method.to_sym
    @params = params
  end
  
  def =~ path
    @pattern =~ path
  end
  
  def handle path, env
    match = @pattern.match(path)
    controller = alloc_controller
    
    controller.template = File.read template_path
    controller.__send__ @method, match.captures, @params, env
    
    Layout.new(controller).render
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
  
  def template_path
    Mustache.template_path + "/#{@klass.downcase}/#{@method}.mustache"
  end
end
