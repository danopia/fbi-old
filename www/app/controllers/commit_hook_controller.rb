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
		
		data['commits'].each do |commit|
		
			# previous commit?
			dup = `grep sha1s.txt #{commit['id']}`.size > 0
			if dup
				next if !data['repository']['fork']
				commit['message'] << ' (merged into upstream from fork --FBI)'
			else
				`echo #{commit['id']} >> sha1s.txt`
			end
			
			output = {
				:project => data['repository']['name'],
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
