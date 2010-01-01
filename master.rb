#!/usr/bin/env ruby
require 'rubygems'
require 'on_irc'

bot = IRC.new do
  nick 'FBI-Control'
  ident 'fbi'
  realname 'Controller/runner for the FBI project bot system'

  server :main do
    address 'irc.eighthbit.net'
  end
end
$bot = bot

class ModuleRunner < EventMachine::Connection
	attr_accessor :name, :script
  
	def self.runners
		@@runners ||= {}
	end
  def runners
    @@runners ||= {}
  end
  
  def self.add_runner name, script
		EM.next_tick do
      EM.popen "ruby ./#{script}.rb 2>&1", ModuleRunner, name, script
		end
  end

	def initialize name, script
		super
		
    @name = name
		@script = script
    
    $bot[:main].send_cmd :privmsg, '#bots', "Started #{@name} (#{@script})"
    puts "Started #{@name} (#{@script})"
		
		runners[name] = self
	end
	
	def replace
		close_connection
		self.class.add_runner @name, @script
	end
	
	def receive_data data
		@buffer += data
		while @buffer.include? "\n"
			line = @buffer.slice! 0, @buffer.index("\n") + 1
			puts "#{@name}: #{line}"
		end
	end

	def unbind
		puts "\e[0;1;31m#{@name}: DIED with exit status #{get_status.exitstatus}\e[0m"
    $bot[:main].send_cmd :privmsg, '#bots', "#{@name} has \002DIED\002! Exit code: #{get_status.exitstatus}"
	end
end

modules = {
  'server' => 'server',
  'udp' => 'in/udp',
  'irc' => 'out/irc',
  'github' => 'irc/github',
  'cmds' => 'irc/misc_commands',
}


bot[:main].on '001' do
  join '#bots'
  join '#illusion'

  # doesn't go here
  modules.each_pair do |name, script|
    ModuleRunner.add_runner name, script
  end
end
 
bot.on :privmsg do
  next unless sender.host == 'danopia::EighthBit::staff'
  
  args = params[1].split
  command = args.shift.downcase
  case command
  
    when 'restart'
      runner = ModuleRunner.runners[args.shift]
      runner.replace
      respond "Restarted #{runner.name} with another instance of #{runner.script}."
  
    when 'stop'
      runner = ModuleRunner.runners[args.shift]
      runner.close_connection
      respond "Halting #{runner.name}."
    
    when 'add'
      ModuleRunner.add_runner args.shift, args.shift
  end
end
 
bot.on :ping do
  pong params[0]
end
 
bot.on :all do
  p = "(#{sender}) " unless sender.empty?
  puts "#{server.name}: #{p}#{command} #{params.inspect}"
end
 
bot.connect
