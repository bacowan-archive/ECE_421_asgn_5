require 'xmlrpc/server'
require 'logger'
require 'thread'
require_relative '../src/model/Game'
require_relative 'DatabaseProxy'
require_relative 'GameProxy'
require_relative 'Contracts'

DEFAULT_MAX_GAMES = 5
OTHER_PLAYER_LEFT_TOKEN = 'OTHER_PLAYER_LEFT_TOKEN'

class GameServerCls

  include Contracts

  INTERFACE = XMLRPC::interface('game') {
    meth 'Array getNotification(String, int)', 'get a notification from the server when the server has one', 'getNotification'
    meth 'array put(String, int)', 'put a piece (of the client) in the given column', 'put'
    meth 'boolean quit(String, String)', 'quit the game and disconnect from the server', 'quit'
    meth 'boolean save()', 'save the current game state', 'save'
    meth 'Hash getStats()', 'get the stats of the "tournament"', 'getStats'
    meth 'Array connectToGame(String, String)', 'connect to the game of the first string, as the user of the second string. Return the game type, and the username of the host user.', 'connectToGame'
    meth 'String hostGame(String, String, String, Array)', 'host a game as a user of the given string, and the game type of the third string'
    meth 'Array loadGame(String, String)', 'load the game of the first string as the user of the second string. Return the game type, and the username of the host user.', 'loadGame'
  }


  # first param: max games that can take place at once
  def initialize(*args)
    if args.length > 0
      @maxGames = args[0]
    else
      @maxGames = DEFAULT_MAX_GAMES
    end
    @gameSessions = Hash.new # map of gameNames to their respective game connection info objects
    # TODO: make a lock around the hash, or make it multi-threaded (one for each game)
    @gameCount = 0 # number of games in session
    @database = DatabaseProxy.new
    @log = Logger.new(STDOUT)
    @stopServer = false
    @stopServerMutex = Mutex.new
    @databaseProxy = DatabaseProxy.new
    @log.debug('server started')
  end

  def _getNotificationPreconditions(gameName,notificationNum)
    #begin
    #  assert(@gameSessions.has_key? gameName, 'game is not in the set of games')
    #  assert(@gameSessions[gameName].
  end

  # asynchronously get a notification. Note that this function must be called asynchronously from the client
  def getNotification(gameName, notificationNum)
    @log.debug('getting ' + notificationNum.to_s + '\'th notification for ' + gameName)
    notification = false
    while !notification and !@stopServer
      # poll for notificaion
      sleep(1)
      notification = @gameSessions[gameName].getNotification(notificationNum)
      if @gameSessions[gameName].nPlayersPresent == 0 # some extra cleanup
        @gameSessions.delete(gameName)
        return [Game.UNKNOWN_EXCEPTION]
      end
    end

    @log.debug(notificationNum.to_s + '\'th notification for ' + gameName + ' is processing')

    notification.each_with_index { |item, index|
      if item.is_a? Board
        notification[index] = notification[index].getBoard
      end
    }
    if notification[0] == Game.UNKNOWN_EXCEPTION
      notification[1] = notification[1].to_s
      @log.debug('exception has occured: ' + notification[1])
    end

    @log.debug(notificationNum.to_s + '\'th notification for ' + gameName + ' is sending')

    return notification
  end


  # start a new game
  def hostGame(gameName,userName,gameType,dimensions)
    @log.debug('hosting game ' + gameName + '. Host user: ' + userName + '. Game Type: ' + gameType + '. Dimensions: ' + dimensions.to_s)
    if @gameCount < @maxGames # start a new game
      begin
        @gameSessions[gameName] = GameProxy.new(gameName,gameType,dimensions,@databaseProxy,@log)
        @gameSessions[gameName].addPlayer(userName)
        return ''
      rescue
        message = 'game creation step failed for game: ' + gameName + '. Host user: ' + userName + '. Game Type: ' + gameType + '. Dimensions: ' + dimensions.to_s
        @log.debug(message)
        return message # TODO: make this a custom error
      end
    end
    message = 'cound not host game: ' + gameName + '. Limit for number of games on server met.'
    @log.debug(message)
    return message
  end


  # connect to a game that has already been loaded onto the server
  # gameName: the name of the game to join
  # userName: the name of the user joining
  def connectToGame(gameName,userName)
    @log.debug('connecting to game: ' + gameName + ' as user: ' + userName)
    if @gameSessions.has_key?(gameName) # join the existing game
      if not @gameSessions[gameName].addPlayer(userName)
        message = 'game "' + gameName + '" is full, and user "' + userName + '" is not a part of the game. Or user "' + userName + '" is already in the game.'
        @log.debug(message)
        return [message]
      end
      @log.debug('user "' + userName + '" has connected to game "' + gameName + '"')
      return ['', @gameSessions[gameName].gameType]
    end # no such game
    message = 'game "' + gameName + '" does not exist'
    @log.debug(message)
    return [message]
  end


  # place a piece in the given column of the given game
  def put(gameName, column)
    @log.debug('placing piece in game "' + gameName + '" in column ' + column.to_s)
    begin
      ret = @gameSessions[gameName].put(column)
      @log.debug('piece in game "' + gameName + '" in column ' + column.to_s + ' has been placed')
      return ret
    rescue
      @log.debug('something went wrong when placing piece in game "' + gameName + '" in column "' + column.to_s)
    end
    return [Game.UNKNOWN_EXCEPTION]
  end


  # quit the game
  def quit(gameName, username)
    @log.debug('player "' + username + '" is leaving game "' + gameName + '"')
    if @gameSessions[gameName].playerLeave(username)
      #@notify([OTHER_PLAYER_LEFT_TOKEN])
      @log.debug('player "' + username + '" has left game "' + gameName + '"')
      return true
    end
    @log.debug('something went wrong; player "' + username + '" could not leave game "' + gameName + '"')
    return false
  end


  # save the game for later
  def save(gameName)
    @log.debug('saving game "' + gameName + '"')
    begin
      game = Marshal.dump(@gameSessions[gameName])
      @databaseProxy.saveGame(gameName,game)
      @log.debug('game "' + gameName + '" was saved')
      return true
    rescue Mysql::Error => e
      @log.debug('game "' + gameName + '" could not be saved: ' + e.to_s)
      return false
    end
  end


  # load a saved game
  def loadGame(gameName, username)
    @log.debug('trying to load game "' + gameName + '", with user "' + username + '" hosting')
    begin
      if @gameCount >= @maxGames
        message = 'too many games already in session to load game "' + gameName + '"'
        @log.debug(message)
        return [false,message]
      end
      game = @databaseProxy.loadGame(gameName)
      if game == nil
        message = 'game "' + gameName + '" could not be loaded. Perhaps the game was never saved, or never existed.'
        @log.debug(message)
        return [false,message]
      end
      @gameSessions[gameName] = Marshal.load(game)
      @gameSessions[gameName].addPlayer(username)
    rescue Mysql::Error => e
      message = 'game "' + gameName + '" could not be loaded due to sql error: ' + e.to_s
      @log.debug(message)
      return [false,message]
    end
    @log.debug('game "' + gameName + '" has been loaded with user "' + username + '" hosting')
    return [@gameSessions[gameName].gameType,@gameSessions[gameName].hostUser]
  end


  # get a list of statistics for the overall "tournament"
  def getStats
    return @databaseProxy.getAllUserStats
  end

  # tell anyone listening that it's time to shut down the server
  def sendShutdownNotification
  end


  def _invariants
    
  end


end
