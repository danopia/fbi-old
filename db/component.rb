#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), '..', 'common', 'client')

require File.join(File.dirname(__FILE__), 'database')

db = FBI::Database.new

client = FBI::Client.new 'db', 'hil0l'
client.subscribe_to '#db'

client.on :authed do |data|
  #puts "authed"
end

client.on :subscribed do |channels|
  #puts "subscribed"
end

client.on :publish do |origin, target, private, data|
  #puts "got packet"
  client.send origin, {:tables => db.sequel.tables}
end

client.start_loop
