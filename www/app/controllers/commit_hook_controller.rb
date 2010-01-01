require 'socket'
require 'json'

class CommitHookController < ApplicationController
	protect_from_forgery :only => []
	
	def github
		return unless params['payload']
		data = JSON.parse params['payload']
		
		# merge floods
		if data['commits'].size > 3
			data['commits'].shift until data['commits'].size == 3
			data['commits'].first['message'] = "(previous commits dropped --FBI) " + data['commits'].first['message']
		end
		
		data['commits'].pop if data['commits'].size > 1 && data['commits'].last['message'] =~ /^Merge remote branch/ && data['repository']['fork']
		
		data['commits'].each do |commit|
		
			# previous commit?
			dup = `grep #{commit['id']} sha1s.txt`.size > 0
			if not dup
				`echo #{commit['id']} >> sha1s.txt`
				
				dup = `grep #{commit['timestamp']} timestamps.txt`.size > 0
				`echo #{commit['timestamp']} >> timestamps.txt` unless dup
			end
			
			if dup
				next if data['repository']['fork'] || !(commit['message'] =~ /^Merge remote branch/)
				commit['message'] << ' (merged into upstream from fork --FBI)'
			end
			
			output = {
				:project => data['repository']['name'],
				:project2 => (data['repository']['fork'] ? data['repository']['owner']['name'] : nil),
				:author => commit['author'],
				:branch => data['ref'].split('/').last,
				:commit => commit['id'],
				:message => commit['message'],
				:url => commit['url']
			}
			send_commit output
		end
		
		render :text => 'Processed.'
	end

	protected
	def send_commit data
		sock = UDPSocket.open
		sock.send data.to_json + "\n", 0, 'localhost', 1337
		sock.close
	end
end
