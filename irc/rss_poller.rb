require 'command_provider'

require 'open-uri'
require 'hpricot'

require 'sequel'
require 'logger'

DB = Sequel.sqlite 'rss.db'
DB.loggers << Logger.new($stdout)

begin
	DB.schema :feeds
rescue Sequel::Error # no table
	DB.create_table :feeds do
		primary_key :id
		
		string :title, :unique => true, :null => false
		string :url, :unique => true, :null => false
		string :last_item, :null => true
		string :created_by, :null => false
		
		boolean :active, :default => true
		
    Time :created_at
   end
	
	DB.create_table :subs do
		primary_key :id
		foreign_key :feed_id, :feeds
		
		integer :server, :null => false
		string :channel, :null => false
  end
end

Feeds = DB[:feeds]
Subs = DB[:subs]

def parse url
	Hpricot::XML(open(url).read)/'item'
end
def shorten_url url
	open('http://is.gd/api.php?longurl=' + url).read
end

class RSSPoller < CommandProvider
	auth 'rss poller', 'hil0l'
	
	on :rss do |data|
		next unless data['admin']
		command = data['args'].shift
		case command
		
			when 'add'
				title = data['args'].shift
				url = data['args'].join ' '
				next unless url && url.size > 0
				
				feed = Feeds.where({:title => title} | {:url => url}).first
				unless feed
					id = Feeds.insert(
						:title => title,
						:url => url,
						:created_by => data['sender']['host'],
						:created_at => Time.now
					)
					feed = Feeds.where(:id => id).first
				end
				
				Subs.insert(
					:feed_id => feed[:id],
					:server => data['server'],
					:channel => data['channel']
				)
				reply_to data, 'Added.'
		
			when 'remove'
				title = data['args'].shift
				feed = Feeds.where(:title => title).first
				
				Subs.where(
					:feed_id => feed[:id],
					:server => data['server'],
					:channel => data['channel']
				).delete
				reply_to data, 'Removed.'
		end
	end
	
	start do
		EM.add_periodic_timer 15*60 do
			Feeds.where(:active => true).all.each do |feed|
				items = parse feed[:url]
				
				item = items.find{|node| node.at('title').innerText == feed[:last_item]}
				items = items[0, items.index(item)] if item
				
				next if items.size == 0
				
				Feeds.where(:id => feed[:id]).update(:last_item => items.first.at('title').innerText)
				
				Subs.where(:feed_id => feed[:id]).each do |sub|
					items[0,3].each do |item|
						send_to sub[:server], sub[:channel], "\002#{feed[:title]}:\017 #{item.at('title').innerText} \00302<\002\002#{shorten_url item.at('link').innerText}>"
					end
				end
			end
		end
	end
end
