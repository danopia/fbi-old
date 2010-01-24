require 'open-uri'

module FBI
  def self.shorten_url url
    open('http://is.gd/api.php?longurl=' + url).read
  rescue OpenURI::HTTPError => ex
    puts "Error while shrinking #{url}: #{ex.message}"
    url
  end
  
  def self.shorten_url_if_present data
    if data.has_key? 'url'
      data['shorturl'] = shorten_url data['url']
    end
  end
end
