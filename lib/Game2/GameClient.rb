require 'xmlrpc/client'
require_relative 'GameServer'
require_relative 'GameClientObj'

module GameClient
	def start
		#server = XMLRPC::Client.new(ENV['HOSTNAME'], '/RPC2', GameServer.DEFAULT_PORT, nil, nil, nil, nil, nil, 9999)
		client = GameClientObj.new(ENV['HOSTNAME'], '/RPC2', GameServer.DEFAULT_PORT)
		client.start
	end
end
