#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), '..', 'common', 'client')

class Hash
  def symbolify!
    self.each_pair do |key, val|
      next if key.is_a? Symbol
      
      self[key.to_sym] = val
      self.delete key
    end
  end
end

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
  case data['method']
    when 'introspect'
      client.send origin, :tables => db.sequel.tables, :method => 'introspect', :response => true
    
    when 'tables'
      client.send origin, :tables => db.sequel.tables, :method => 'tables', :response => true
    
    when 'select'
      criteria = data['criteria'] || {}
      criteria.symbolify!
      results = db[data['table'].to_sym]
      results = results.filter(criteria) if criteria.any?
      client.send origin, :records => results.all, :method => 'select', :response => true
    
    when 'first'
      criteria = data['criteria'] || {}
      criteria.symbolify!
      results = db[data['table'].to_sym]
      results = results.filter(criteria) if criteria.any?
      client.send origin, :record => results.first, :method => 'first', :response => true
    
    when 'insert'
      record = data['record']
      record.symbolify!
      table = db[data['table'].to_sym]
      client.send origin, :id => table.insert(record), :method => 'insert', :response => true
    
    when 'update'
      criteria = data['criteria'] || {}
      criteria.symbolify!
      
      record = data['record'] || {}
      record.symbolify!
      
      db[data['table'].to_sym].filter(criteria).update record
      client.send origin, :result => :success, :method => 'update', :response => true
    
    when 'delete'
      criteria = data['criteria'] || {}
      criteria.symbolify!
      
      db[data['table'].to_sym].filter(criteria).delete
      client.send origin, :result => :success, :method => 'delete', :response => true
  end
end

client.start_loop
