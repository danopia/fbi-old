require 'socket'
require 'json'

class CommitHookController < ApplicationController
	protect_from_forgery :only => []
	
	def github
		return unless params[:payload]
		data = JSON.parse params[:payload]
		data['commits'].each do |commit|
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
