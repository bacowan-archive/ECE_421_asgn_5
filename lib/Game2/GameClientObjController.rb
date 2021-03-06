require 'thread'

class GameClientObjController
	def initialize(host,path,port)
		@view = nil
		@done = false
		@host = host
		@path = path
		@port = port
		#@server = server
		#@serverProxy = @server.proxy('game')
		@printMutex = Mutex.new
		@gameName = nil
		@notificationCount = 0
	end

	def server
		XMLRPC::Client.new(@host, @path, @port, nil, nil, nil, nil, nil, 9999)
	end

	def serverProxy
		server.proxy('game')
	end

	def setView(view)
		@view = view
	end

	def put(gameName, column)
		ret = serverProxy.put(gameName,column.to_i)
	end

	def quit(gameName, userName)
		serverProxy.quit(gameName,userName)
		@done = true
	end

	def save(gameName)
		ret = serverProxy.save(gameName)
	end

	def getStats()
		ret = serverProxy.getStats()
		return ret
	end

	def connectToGame(gameName,userName)
		@done = false
		ret = serverProxy.connectToGame(gameName,userName)
		if ret[0] == ''
			@gameName = gameName
		end
		return ret
	end

	def hostGame(gameName, userName, gameType, dims)
		@done = false
		ret =  serverProxy.hostGame(gameName,userName,gameType,[dims[0].to_i,dims[1].to_i])
		if ret == ''
			@gameName = gameName
		end
		return ret
	end

	def loadGame(gameName, userName)
		@done = false
		ret = serverProxy.loadGame(gameName,userName)
		if ret[0] != false
			@gameName = gameName
		end
		return ret
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
		temp = server.call_async('game.getNotification', @gameName, @notificationCount )
		@notificationCount += 1
		@view.notify(temp)
	end
end
