require 'xmlrpc/client'
require_relative 'GameServer'
require_relative 'GameClientObj'

module GameClient
	def start
		server = XMLRPC::Client.new(ENV['HOSTNAME'], '/RPC2', GameServer.DEFAULT_PORT)
		client = GameClientObj.new(server)
		client.start
	end
end
