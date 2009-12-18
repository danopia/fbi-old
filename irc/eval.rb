require 'command_provider'
require 'spidermonkey'

class EvalCommands < CommandProvider
	auth 'lang evaler', 'hil0l'
	
	@@sessions = {}
	on :js do |data|
		session = @@sessions[data['sender']['nick']] ||= create_session(data)
		session.set_property 'channel', data['channel']
		
		output = []
		session.global.function("print") {|x| output << x}

		time = 0
		session.global.function 'sleep' do |x|
			time += x.to_f
			if time < 3
				sleep time
			else
				raise StandardError, 'You can only sleep up to 3 seconds.'
			end
		end
		
		begin
			puts data['args'].join(' ')
			output << session.eval(data['args'].join(' '))
			output.compact!
			reply_to data, output.any? ? output.join(', ').gsub("\n", ' ') : 'Nothing was returned'
		rescue => ex
			reply_to data, "An error occured. #{ex.message}"
		end
	end
	
	def self.create_session data
		session = SpiderMonkey::Context.new
		session.set_property 'nick', data['sender']['nick']
		session
	end
	
	start
end
