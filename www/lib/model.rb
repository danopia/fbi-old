class Model
  attr_reader :id, :data
  
  
  def self.table_name= name
    @table = name
  end
  def self.table_name name=nil
    return @table = name if name
    return @table if @table
    
    @table = self.name.to_s
    @table[0] = @table[0].chr.downcase
    @table.gsub!(/[A-Z]/) { |s| "_#{s.downcase}"}
    @table = "#{@table}s"
  end
  def table_name; self.class.table_name; end
  
  def self.table
    DB[table_name.to_sym]
  end
  def table; self.class.table; end
  
  
  def self.find filters
    filters = {:id => filters} if filters.is_a? Fixnum
    us = table.filter(filters).first
    us && self.new(us)
  end
  
  def self.where filters
    table.filter(filters).map {|us| self.new us }
  end
  
  def self.all
    table.all.map {|us| self.new us }
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
      @id = table << @data
    else
      @data[:modified_at] = Time.now
      table.where(:id => @id).update @data
    end
  end
  
  def destroy!
    table.where(:id => @id).delete
  end
  
  
  def == other
    other.class == self.class && other.id == self.id && other.data == self.data
  end
end
