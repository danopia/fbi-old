class ServicesController < Controller
  attr_reader :service, :services, :projects, :mine
  
  def list captures, params, env
    @mine = env[:user].id == 1
    @services = Service.all
  end
  
  def show captures, params, env
    @mine = env[:user].id == 1
    @service = Service.find :slug => captures.first
  end
  
  def new captures, params, env
    return unless env[:user].id == 1
    @service = Service.new
    
    if env['REQUEST_METHOD'] == 'POST'
      data = CGI.parse env['rack.input'].read
      
      @service.title = data['title'].first
      @service.slug = data['slug'].first
      @service.url_format = data['url_format'].first
      @service.website = data['website'].first
      @service.mirrorable = data['mirrorable'].any?
      @service.explorable = data['explorable'].any?
      
      @service.save

      #render :text => 'The project has been registered.'
      
      @mine = true
      render :path => 'services/show'
    end
  end
  
  def edit captures, params, env
    return unless env[:user].id == 1
    
    @service = Service.find :slug => captures[0]
    
    if env['REQUEST_METHOD'] == 'POST'
      data = CGI.parse env['rack.input'].read
      
      @service.title = data['title'].first
      @service.slug = data['slug'].first
      @service.url_format = data['url_format'].first
      @service.website = data['website'].first
      @service.mirrorable = data['mirrorable'].any?
      @service.explorable = data['explorable'].any?
      
      @service.save
      
      #render :text => 'The service has been updated.'
      @mine = true
      render :path => 'services/show'
    end
  end
end
