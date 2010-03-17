class Renderer < Mustache
  attr_accessor :template, :file, :object
  
  def initialize file, object, env
    @file = file
    @object = object
    @env = env
  end
  
  def render args={}
    path = "#{Mustache.template_path}/#{@file}.#{self.class.template_extension}"
    @template ||= File.read(path)
    content = super @template, object
    #p context.stack.size
    #context.pop
    
    layout = "#{Mustache.template_path}/layout.#{self.class.template_extension}"
    super File.read(layout), {:yield => content, :user => @env[:user], :session => @env[:session], :loggedout => !@env[:user]}
  end
end
