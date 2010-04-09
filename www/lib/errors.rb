module HTTP
  class Error < StandardError
    attr_accessor :code
    
    def initialize code=500, message=nil
      @code = code
      super message
    end
  end

  class Redirect < Error
    attr_accessor :path
    
    def initialize code=302, path='/', message=nil
      @path = path
      super code, message || "You are being redirected to #{path}."
    end
  end
  
  
  # 200 OK
  class OK < Error
    def initialize message=nil
      super 200, message
    end
  end
  
  # 201 Created
  class Created < Redirect
    def initialize path='/', message=nil
      super 201, path, message
    end
  end
  
  # 301 Moved Permanently
  class Moved4Good < Redirect
    def initialize path='/', message=nil
      super 301, path, message
    end
  end
  
  # 302 Found
  class Found < Redirect
    def initialize path='/', message=nil
      super 302, path, message
    end
  end
  
  # 303 See Other
  class SeeOther < Redirect
    def initialize path='/', message=nil
      super 303, path, message
    end
  end

  # 403 Forbidden
  class Forbidden < Error
    def initialize message=nil
      super 403, message || 'You are not allowed to access this page.'
    end
  end

  # 404 Not Found
  class NotFound < Error
    def initialize message=nil
      super 404, message || 'The page you were looking for could not be found.'
    end
  end

  # 410 Gone
  class Gone < Error
    def initialize message=nil
      super 410, message || 'The page you were looking for has disappeared.'
    end
  end

end
