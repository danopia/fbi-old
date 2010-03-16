class Controller
  attr_accessor :action
  
  def render args={}
    return @rendered if @rendered
    
    renderer = Renderer.new args[:path], args[:context]
    renderer.file ||= "#{self.class.name.downcase.sub('controller','')}/#{@action}"
    renderer.object ||= self
    @rendered = renderer.render
  end
end
