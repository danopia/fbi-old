require 'socket'

require 'rubygems'
require 'json'

class Hash
  def symbolify!
    self.each_pair do |key, val|
      next if key.is_a? Symbol
      
      self[key.to_sym] = val
      self.delete key
    end
  end
end

module FBI
  class Model
    attr_reader :id, :data
    
    @@fbi_sock = nil
    
    # Hacky hacky hacky...
    def self.fbi_sock
      return @@fbi_sock if @@fbi_sock
      
      @@fbi_sock = TCPSocket.new 'danopia.net', 5348
      @@fbi_sock.puts({:action => 'auth', :user => 'db_worker-' + rand.to_s, :secret => 'hil0l'}.to_json)
      2.times { @@fbi_sock.gets }
      @@fbi_sock
    end
    
    def self.fbi_packet args={}, target='#db'
      fbi_sock.puts({:action => 'publish', :target => target, :data => args}.to_json)
      data = JSON.parse fbi_sock.gets
      data['data']
    end
    def fbi_packet args={}; self.class.fbi_packet args; end
    
    
    def self.from_json json
      self.new JSON.parse(json)
    end
    
    
    def self.table= name
      @table = name
    end
    def self.table name=nil
      return @table = name if name
      return @table if @table
      
      @table = self.name.to_s
      @table[0] = @table[0].chr.downcase
      @table.gsub!(/[A-Z]/) { |s| "_#{s.downcase}"}
      @table = "#{@table}s"
    end
    def table; self.class.table; end
    
    
    def self.find filters
      filters = {:id => filters} if filters.is_a? Fixnum
      rec = fbi_packet({:method => 'first', :table => table, :criteria => filters})['record']
      rec && rec.symbolify! && self.new(rec)
    end
    
    def self.first amount=1, filters={}
      filters = {:id => filters} if filters.is_a? Fixnum
      recs = fbi_packet({:method => 'select', :table => table, :criteria => filters, :count => amount})['records']
      recs.map {|rec| rec.symbolify!; self.new rec }
    end
    
    def self.where filters
      filters = {:id => filters} if filters.is_a? Fixnum
      recs = fbi_packet({:method => 'select', :table => table, :criteria => filters})['records']
      recs.map {|rec| rec.symbolify!; self.new rec }
    end
    
    def self.all
      recs = fbi_packet({:method => 'select', :table => table})['records']
      recs.map {|rec| rec.symbolify!; self.new rec }
    end
    
    
    def self.create data={}
      record = self.new data
      record.save
      record
    end
    
    
    def initialize data={}
      @data = data
      @id = @data.delete(:id)
    end
    
    def created_at; @data[:created_at]; end
    def modified_at; @data[:modified_at]; end
    
    def new_record?
      !@id
    end
    
    def save
      if new_record?
        @data[:created_at] = Time.now
        @id = fbi_packet({:method => 'insert', :table => table, :record => @data})['id']
      else
        @data[:modified_at] = Time.now
        fbi_packet({:method => 'update', :table => table, :criteria => {:id => @id}, :record => @data})
      end
      self
    end
    
    def destroy!
      fbi_packet({:method => 'delete', :table => table, :criteria => {:id => @id}})
    end
    
    
    def == other
      other.class == self.class && other.id == self.id && other.data == self.data
    end
    
    
    def inspect
      output = "#<#{self.class} "
      output << (new_record? ? 'id=[unsaved]' : "id=#{@id}")
      
      @data.each_pair do |key, val|
        output << ", #{key}=#{val.inspect}"
      end
      
      output + '>'
    end
    
    
    def to_i; @id; end
    def to_s; @data[:slug]; end
    
    def to_hash
      @data.merge({:id => @id})
    end
    def to_json; to_hash.to_json; end
  end
end
