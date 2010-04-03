class Controller
  attr_accessor :action, :env
  
  def render args={}
    return @rendered if @rendered
    
    renderer = Renderer.new args[:path], args[:context], @env
    renderer.file ||= "#{self.class.name.downcase.sub('controller','')}/#{@action}"
    renderer.object ||= self
    @rendered = renderer.render args
  end
  
  def post?
    @env['REQUEST_METHOD'] == 'POST'
  end
  
  def form_fields
    return @form_fields if !post? || @form_fields
    
    @form_fields = CGI.parse env['rack.input'].read
    
    @form_fields.each_key do |k|
      next if @form_fields[k].size > 1
      @form_fields[k] = @form_fields[k].first
    end
  end
end
