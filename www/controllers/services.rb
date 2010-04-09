class ServicesController < Controller
  attr_reader :service, :services, :projects, :mine
  
  def list captures, params, env
    @mine = env[:user].id == 1
    @services = Service.all
  end
  
  def show captures, params, env
    @mine = env[:user].id == 1
    @service = Service.find :slug => captures.first
    raise HTTP::NotFound unless @service
  end
  
  def new captures, params, env
    raise HTTP::Forbidden unless env[:user].id == 1
    
    @service = Service.new
    
    return unless post?
    
    @service.title = form_fields['title']
    @service.slug = form_fields['slug']
    @service.url_format = form_fields['url_format']
    @service.website = form_fields['website']
    @service.mirrorable = form_fields['mirrorable']
    @service.explorable = form_fields['explorable']
    @service.save

    #render :text => 'The project has been registered.'
    raise HTTP::Found, @service.show_path
  end
  
  def edit captures, params, env
    raise HTTP::Forbidden unless env[:user].id == 1
    
    @service = Service.find :slug => captures[0]
    raise HTTP::NotFound unless @service
    
    return unless post?
    
    @service.title = form_fields['title']
    @service.slug = form_fields['slug']
    @service.url_format = form_fields['url_format']
    @service.website = form_fields['website']
    @service.mirrorable = form_fields['mirrorable']
    @service.explorable = form_fields['explorable']
    @service.save
    
    #render :text => 'The service has been updated.'
    raise HTTP::Found, @service.show_path
  end
end
