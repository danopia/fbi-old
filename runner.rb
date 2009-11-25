require 'rubygems'
require 'eventmachine'

sleep 1

module KeyboardHandler
	def post_init
		@buffer = ''
		
		prepare_modes
		self.cursor = false
	rescue => e
		p e
		sleep 1
	end
	
	def cursor=(show)
		EM.next_tick do
			print "\e[?25h" if show
			print "\e[?25l" unless show
			$stdout.flush
		end
	end
	def self.cursor=(show)
		print "\e[?25h" if show
		print "\e[?25l" unless show
		$stdout.flush
	end
	
	def receive_data data
		@buffer += data
		
		@buffer.gsub! "\000", "\b" # lol?
		while @buffer.include?("\b") && @buffer.index("\b") > 0
			@buffer.slice! @buffer.index("\b") - 1, 2
		end
		@buffer.gsub! "\b", ''
		
		while @buffer.include? "\n"
			line = @buffer.slice! 0, @buffer.index("\n") + 1
			line.chomp!
			receive_line line
		end
		
		EM.next_tick do
			print "\e[0m"
			place $screen_lines + 2, 1, @buffer
			print "\e[K"
			$stdout.flush
		end
		
	rescue => e
		ModuleRunner.runners.first << e.inspect
	end
	
	def receive_line line
		args = line.split
		return if args.empty?
		
		case args.shift
			when 'exit'
				unbind
				EM.stop_event_loop
				
			when 'redraw'
				ModuleRunner.redraw_screen
				
			when 'clear'
				window = args.shift.to_sym
				window = ModuleRunner.runners.find {|runner| runner.key == window }
				return unless window
				window.clear
				
			when 'restart'
				window = args.shift.to_sym
				window = ModuleRunner.runners.find {|runner| runner.key == window }
				return unless window
				window.replace
		end
	end
	
	def unbind
		undo_modes
		self.cursor = true
	end
	def self.unbind
		undo_modes
		self.cursor = true
	end
	
	def place row, col, text
		print "\e[#{row.to_i};#{col.to_i}H#{text}"
	end
	
	
	
	# yay grep
	TIOCGWINSZ = 0x5413
	TCGETS = 0x5401
	TCSETS = 0x5402
	ECHO   = 8 # 0000010
	ICANON = 2 # 0000002

	#~ # thanks google for all of this
	#~ def self.terminal_size
		#~ rows, cols = 25, 80
		#~ buf = [0, 0, 0, 0].pack("SSSS")
		#~ if $stdout.ioctl(TIOCGWINSZ, buf) >= 0 then
			#~ rows, cols, row_pixels, row_pixels, col_pixels = buf.unpack("SSSS")[0..1]
		#~ end
		#~ return [rows, cols]
	#~ end
	
	# had to convert these from C... fun
	def prepare_modes
		@@old_modes = [0, 0, 0, 0, 0, 0]
		buf = @@old_modes.pack("IIIICC")
		$stdout.ioctl(TCGETS, buf) # get current mode
		@@old_modes = buf.unpack("IIIICC")
		new_modes = @@old_modes.clone
		new_modes[3] &= ~ECHO # echo off
		new_modes[3] &= ~ICANON # one char @ a time
		buf = new_modes.pack("IIIICC")
		$stdout.ioctl(TCSETS, buf) # set new terminal mode
	end
	def undo_modes # restore previous terminal mode
		$stdout.ioctl(TCSETS, @@old_modes.pack("IIIICC"))
	end
	def self.undo_modes # restore previous terminal mode
		$stdout.ioctl(TCSETS, @@old_modes.pack("IIIICC"))
	end
	#def print *args;end
end

class ModuleRunner < EventMachine::Connection
	#def print *args;end
	attr_accessor :key

	RUNNERS = []
	
	def self.runners
		RUNNERS
	end
	
	def self.redraw_screen
		print "\e[2J" # clear all
		
		RUNNERS.each do |runner|
			runner.autosize
			runner.redraw
		end
		
		redraw_topbars
	end
	
	def self.redraw_topbars
		RUNNERS.each do |runner|
			runner.draw_topbar
		end
	end
	
	def initialize script, key, row, col
		super
		
		@script = script
		@key = key
		@cell = [row, col]
		@data = []
		@title_color = '1;32'
		@buffer = ''
		
		autosize
		draw_frame
		ModuleRunner.redraw_topbars
		
		RUNNERS << self
	end
	
	def replace
		RUNNERS.delete self
		close_connection
		EM.next_tick do
			EM.popen "ruby ./#{@script}.rb 2>&1", ModuleRunner, @script, @key, *@cell
		end
	end
	
	def autosize
		@left = ((@cell[1].to_f / $cols) * $screen_cols + 1).to_i
		@right = (((@cell[1] + 1).to_f / $cols) * $screen_cols + 1).to_i
	
		@top = ((@cell[0].to_f / $rows) * $screen_lines + 1).to_i
		@bottom = (((@cell[0] + 1).to_f / $rows) * $screen_lines + 1).to_i
	
		@width = @right - @left
		@height = @bottom - @top
		
		@data.shift while @data.size >= @height
	end
	
	def topbar
		title = " * #{@key} * "
		left = (((@width - 1).to_f / 2) - (title.size.to_f / 2)).to_i
		
		title_colored = "#{color @title_color}#{title}#{color '0;2'}"
		('-' * left) + title_colored + ('-' * (@width - 1 - title.size - left))
	end
	
	def draw_topbar
		print color('0;2')
		place @top, @left, "+#{topbar}+"
	end
	
	def draw_frame
		bottombar = '-' * (@width - 1)
		fillerbar = ' ' * (@width - 1)
		
		draw_topbar # sets color
		place @bottom, @left, "+#{bottombar}+"
		
		(@top + 1).upto @bottom - 1 do |row|
			place row, @left, "|#{fillerbar}|"
		end
		print color('0')
		
		$stdout.flush
	end
	
	def draw_body
		draw_topbar
		
		row = @top + 1
		
		# data lines
		@data.each do |data|
			print color('0')
			place row, @left + 2, data[0, @width-3].ljust(@width - 3)
			row += 1
		end
		
		# blanks
		print color('0')
		row.upto((@bottom - 1).to_i) do |row|
			place row, @left + 2, ' ' * (@width - 3)
		end
		
		$stdout.flush
	end
	
	def redraw
		draw_frame
		draw_body
	end

	def receive_data data
		@buffer += data
		while @buffer.include? "\n"
			line = @buffer.slice! 0, @buffer.index("\n") + 1
			line.chomp!
			self << line
		end
	end

	def unbind
		self << "died with exit status #{get_status.exitstatus}"
		
		@title_color = '0;1;9;31'
		EM.next_tick do
			redraw
			ModuleRunner.redraw_topbars
		end
	end
	
	def clear
		@data.clear
		draw_body
	end
	
	def << line
		line.chomp!
		@data << line.slice!(0, @width - 3) while line.any?
		@data.shift while @data.size >= @height
		
		EM.next_tick do
			draw_body
		end
	end
	
	def place row, col, text
		print "\e[#{row.to_i};#{col.to_i}H#{text}"
	end
	def color codes
		"\e[#{codes}m"
	end
end

MODULES = {
	:server => 'server',
	:irc => 'out/irc',
	:udp => 'in/udp',
	:asdf => 'temp_app',
	#:five => 'test_module',
	#:six => 'test_module',
	#:seven => 'test_module',
	#:eight => 'test_module',
	#:nine => 'test_module',
}

$screen_lines = `tput lines`.to_i - 2
$screen_cols = `tput cols`.to_i - 1

trap 'INT' do
	EM.stop_event_loop
end

EM.run do
	$rows, $cols = case MODULES.size
		when 1: [1, 1]
		when 2: [1, 2]
		when 3: [2, 2]
		when 4: [2, 2]
		when 5: [2, 3]
		when 6: [2, 3]
		when 7: [3, 3]
		when 8: [3, 3]
		when 9: [3, 3]
	end
	
	row = 0
	col = 0
	
	MODULES.each_pair do |key, value|
		EM.popen "ruby ./#{value}.rb 2>&1", ModuleRunner, value, key, row, col
		sleep 1 if key == :server
		
		row += 1
		if row >= $rows
			row = 0
			col += 1
		end
	end
	
	EventMachine::PeriodicTimer.new 2.5 do
		new = [`tput lines`.to_i - 2, `tput cols`.to_i - 1]
		
		if new != [$screen_lines, $screen_cols]
			$screen_lines, $screen_cols = new
			EM.next_tick do
				ModuleRunner.redraw_screen
			end
		end
	end
	
	EM.attach $stdin, KeyboardHandler
end

KeyboardHandler.unbind
