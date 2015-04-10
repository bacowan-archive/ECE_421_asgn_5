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
		ret serverProxy.quit(gameName,userName)
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
		ret = serverProxy.connectToGame(gameName,userName)
		if ret == true
			@gameName = gameName
		end
		return ret
	end

	def hostGame(gameName, userName, gameType, dims)
		ret =  serverProxy.hostGame(gameName,userName,gameType,[dims[0].to_i,dims[1].to_i])
		if ret == true
			@gameName = gameName
		end
		return ret
	end

	def loadGame(gameName, userName)
		ret = serverProxy.loadGame(gameName,userName)
		if ret[0] != ''
			@gameName = gameName
		end
		return ret
	end
	

	def _notifications
		puts 'notificaitons!'
		Thread.new {
			puts 'there'
			while !@done
				puts 'here'
				puts 'game name: ' + @gameName
				if @gameName != nil
					_getNotification
				end
                                sleep(1)
			end
		}
	end

	def _getNotification
		puts 'getting notification!'
		temp = server.call_async('game.getNotification', @gameName, @notificationCount )
		temp.each{|e| 
			print e
			puts ''}
		@notificationCount += 1
		puts "Notify called and returned\n"
		@view.notify(temp)
	end
end
