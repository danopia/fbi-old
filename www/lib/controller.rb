class Controller
  attr_accessor :action, :env
  
  def render args={}
    return @rendered if @rendered
    
    renderer = Renderer.new args[:path], args[:context], @env
    renderer.file ||= "#{self.class.name.downcase.sub('controller','')}/#{@action}"
    renderer.object ||= self
    @rendered = renderer.render
  end
end
