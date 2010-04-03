class Controller
  attr_accessor :action, :env
  
  def render args={}
    return @rendered if @rendered
    
    renderer = Renderer.new args[:path], args[:context], @env
    renderer.file ||= "#{lowercase_name}/#{@action}"
    renderer.object ||= self
    @rendered = renderer.render args
  end
  
  def lowercase_name
    name = self.class.name.sub 'Controller', ''
    name[0,1] = name[0,1].downcase
    name.gsub(/[A-Z]/) {|c| "_#{c.downcase}" }
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
