require 'xmlrpc/client'
require_relative 'GameServer'
require_relative 'GameClientObj'

module GameClient
	def start
		client = GameClientObj.new(ENV['HOSTNAME'], '/RPC2', GameServer.DEFAULT_PORT)
		client.start
	end
end
