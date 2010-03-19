class Renderer < Mustache
  attr_accessor :template, :file, :object
  
  def initialize file, object, env
    @file = file
    @object = object
    @env = env
  end
  
  def render args={}
    content = nil
    
    if args[:text]
      content = args[:text]
    elsif args[:template]
      @template = args[:template]
      content = super @template, object
    else
      path = "#{Mustache.template_path}/#{@file}.#{self.class.template_extension}"
      @template ||= File.read(path)
      content = super @template, object
    end
    
    layout = "#{Mustache.template_path}/layout.#{self.class.template_extension}"
    super File.read(layout), {:yield => content, :user => @env[:user], :session => @env[:session], :loggedout => !@env[:user]}
    
  end
end
