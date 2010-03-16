class Renderer < Mustache
  attr_accessor :template, :file, :object
  
  def initialize file, object
    @file = file
    @object = object
  end
  
  def render args={}
    path = "#{Mustache.template_path}/#{@file}.#{self.class.template_extension}"
    @template ||= File.read(path)
    content = super @template, object
    
    layout = "#{Mustache.template_path}/layout.#{self.class.template_extension}"
    super File.read(layout), {:yield => content}
  end
end
