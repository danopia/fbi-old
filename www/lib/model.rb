class Hash
  def symbolify!
    self.each_pair do |key, val|
      next if key.is_a? Symbol
      
      self[key.to_sym] = val
      self.delete key
    end
  end
end

class Model
  attr_reader :id, :data
  
  def self.fbi_packet args={}
    $fbi_sock.puts({:action => 'publish', :target => '#db', :data => args}.to_json)
    data = JSON.parse $fbi_sock.gets
    p data['data']
    data['data']
  end
  def fbi_packet args={}; self.class.fbi_packet args; end
  
  
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
    rec && rec.symbolify!
    rec && self.new(rec)
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
    @id = @data[:id]
    @data.delete :id
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
  end
  
  def destroy!
    fbi_packet({:method => 'delete', :table => table, :criteria => {:id => @id}})
  end
  
  
  def == other
    other.class == self.class && other.id == self.id && other.data == self.data
  end
end
