module FBI_IRC
class Channel
  attr_accessor :record, :connection, :network, :topic, :users, :in_names, :redirect

  def initialize record, conn=nil
    record = IrcChannel.find record unless record.is_a? IrcChannel
    @record = record
    @users = []
    @connection = conn
    @network = conn.network if conn
  end

  def id; @record.id; end

  def name; @redirect || @record.name; end
  def to_s; @redirect || @record.name; end

  def message msg
    @connection.message self, msg
  end

  def part msg=nil
    @connection.part self, msg
  end
end
end
