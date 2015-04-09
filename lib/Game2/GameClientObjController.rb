require 'thread'

class GameClientObjController
	def initialize(server)
		@view = nil
		@done = false
		@server = server
		@serverProxy = @server.proxy('game')
		@printMutex = Mutex.new
		@gameName = nil
		@notificationCount = 0
	end

	def setView(view)
		@view = view
	end

	def put(gameName, column)
		ret = @serverProxy.put(gameName,column.to_i)
	end

	def quit(gameName, userName)
		ret @serverProxy.quit(gameName,userName)
		@done = true
	end

	def save(gameName)
		ret = @serverProxy.save(gameName)
	end

	def getStats()
		ret = @serverProxy.getStats()
	end

	def connectToGame(gameName,userName)
		ret = @serverProxy.connectToGame(gameName,userName)
		if ret == true
			@gameName = args[1]
		end
	end

	def hostGame(gameName, userName, gameType, dims)
		ret =  @serverProxy.hostGame(gameName,userName,gameType,[dims[0].to_i,dims[1].to_i])
		if ret == true
			@gameName = gameName
		end
	end

	def loadGame(gameName, userName)
		ret =  @serverProxy.loadGame(gameName,userName)
	end
	

	def _notifications
		Thread.new {
			while !@done
				if @gameName != nil
					_getNotification
				end
                                sleep(1)
			end
		}
	end

	def _getNotification
		temp = @server.call_async('game.getNotification', @gameName, @notificationCount )
		@notificationCount += 1
		@view.notify(temp)
	end
end