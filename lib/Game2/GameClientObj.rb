require 'thread'

class GameClientObj
	def initialize(server)
		@done = false
		@server = server
		@serverProxy = @server.proxy('game')
		@printMutex = Mutex.new
		@gameName = nil
		@notificationCount = 0
	end

	def start
		_notifications
		while !@done
			print '>> '
			command = gets
			_parseCommand(command.split)
		end
	end

	def _parseCommand(args)
		if args[0] == 'put'
			ret = @serverProxy.put(args[1],args[2].to_i)
			@printMutex.synchronize {
				puts ret
			}
		elsif args[0] == 'quit'
			ret @serverProxy.quit(args[1],args[2])
			@printMutex.synchronize {
				puts ret
			}
			@done = true
		elsif args[0] == 'save'
			ret = @serverProxy.save()
			@printMutex.synchronize {
				puts ret
			}
		elsif args[0] == 'getStats'
			ret = @serverProxy.getStats()
			@printMutex.synchronize {
				puts ret
			}
		elsif args[0] == 'connectToGame'
			ret = @serverProxy.connectToGame(args[1],args[2])
			if ret == true
				@gameName = args[1]
			end
			@printMutex.synchronize {
				puts ret
			}
		elsif args[0] == 'hostGame'
			ret =  @serverProxy.hostGame(args[1],args[2],args[3],[args[4].to_i,args[5].to_i])
			if ret == true
				@gameName = args[1]
			end
			@printMutex.synchronize {
				puts ret
			}
		elsif args[0] == 'loadGame'
			ret =  @serverProxy.loadGame(args[1],args[2])
			@printMutex.synchronize {
				puts ret
			}
		end
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
		ret = temp#Marshal.load( temp )
		@printMutex.synchronize {
			puts ret
			begin
				puts ''
				print ret[1]
				puts ''
			rescue
			end
		}
	end
end
