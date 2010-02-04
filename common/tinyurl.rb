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
  
  def self.shorten_urls_if_present data
    if data.is_a? Array
      data.each {|entry| shorten_url_if_present entry}
    elsif data.is_a? Hash
      shorten_url_if_present data
    end
  end
end
