require_relative 'Game2/GameServer'
require_relative 'Game2/GameClient'

module Game2

	def startServer
		include GameServer
		start
	end

	def startClient
		include GameClient
		start
	end

end
