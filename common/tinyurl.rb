require 'open-uri'

module FBI
  def self.shorten_url url
    open('http://is.gd/api.php?longurl=' + url).read
  rescue OpenURI::HTTPError => ex
    puts "Error while shrinking #{url}: #{ex.message}"
    url
  end
end
