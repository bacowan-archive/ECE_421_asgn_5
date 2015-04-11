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
    meth 'boolean put(String, int)', 'put a piece (of the client) in the given column', 'put'
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
    #gameCount = 0 # number of games in session
    @database = DatabaseProxy.new
    @log = Logger.new(STDOUT)
    @stopServer = false
    @stopServerMutex = Mutex.new
    @databaseProxy = DatabaseProxy.new
    @log.debug('server started')
  end



  def _getNotificationPreconditions(gameName,notificationNum)
    begin
      assert(@gameSessions.has_key? gameName, 'game is not in the set of games')
      assert(@gameSessions[gameName].getNotification, 'the notification being requested does not exist')
    rescue
      # we might get here if the first contract fails
    end
  end

  def _getNotificationPostconditions(ret)
    begin
      assert(ret[0].is_a? String, 'the array being returned does not start with a string')
    rescue
    end
  end

  # asynchronously get a notification. Note that this function must be called asynchronously from the client
  def getNotification(gameName, notificationNum)

    # preconditions and invariants
    _getNotificationPreconditions(gameName,notificationNum)
    _invariants    

    @log.debug('getting ' + notificationNum.to_s + '\'th notification for ' + gameName)
    notification = false
    while !notification and !@stopServer
      # poll for notificaion
      sleep(1)
      notification = @gameSessions[gameName].getNotification(notificationNum)
      if @gameSessions[gameName].nPlayersPresent == 0 # some extra cleanup
        @gameSessions.delete(gameName)
        ret = [Game.UNKNOWN_EXCEPTION]

        #post-conditions and invariants
        _invariants
        _getNotificationPostconditions(ret)
        
        return ret
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

    _getNotificationPostconditions(ret)
    _invariants

    return notification
  end





  def _hostGamePreconditions(gameName,gameType)
    begin
      #@_hostGamePreconditions_gameCount = gameCount
      #assert_false(@gameSessions.has_key? gameName, 'game already in session')
      #assert(((gameType == 'CONNECT_FOUR') or (gameType == 'OTTO_TOOT')), 'game type not valid')
    rescue
    end
  end

  def _hostGamePostconditions
    begin
      #assert_equal(@_hostGamePreconditions_gameCount+1,gameCount,'new game not added')
    rescue
    end
  end

  # start a new game
  def hostGame(gameName,userName,gameType,dimensions)

    # preconditions and invariants
    _hostGamePreconditions(gameName,gameType)
    _invariants

    @log.debug('hosting game ' + gameName + '. Host user: ' + userName + '. Game Type: ' + gameType + '. Dimensions: ' + dimensions.to_s)
    if gameCount < @maxGames # start a new game
      begin
        @gameSessions[gameName] = GameProxy.new(gameName,gameType,dimensions,@databaseProxy,@log)
        @gameSessions[gameName].addPlayer(userName)

        #postconditions and invariants
        _hostGamePostconditions
        _invariants

        return ''
      rescue => e
        message = 'game creation step failed for game: ' + gameName + '. Host user: ' + userName + '. Game Type: ' + gameType + '. Dimensions: ' + dimensions.to_s
        @log.debug(message)
        return message
      end
    end
    message = 'cound not host game: ' + gameName + '. Limit for number of games on server met.'
    @log.debug(message)
    return message
  end




  def _connectToGamePreconditions(gameName,userName)
    begin
      assert(@gameSessions.has_key? gameName, 'game not in session')
      assert(@gameSessions[gameName].players.has_key? userName, 'given user not in session')
    rescue
    end
  end

  def _connectToGamePostconditions(gameName,userName)
    begin
      assert(@gameSessions[gameName].players[userName], 'given user was not added to the session')
    rescue
    end
  end

  # connect to a game that has already been loaded onto the server
  # gameName: the name of the game to join
  # userName: the name of the user joining
  def connectToGame(gameName,userName)

    #preconditions and invariants
    _connectToGamePreconditions(gameName,userName)
    _invariants

    @log.debug('connecting to game: ' + gameName + ' as user: ' + userName)
    if @gameSessions.has_key?(gameName) # join the existing game
      if not @gameSessions[gameName].addPlayer(userName)
        message = 'game "' + gameName + '" is full, and user "' + userName + '" is not a part of the game. Or user "' + userName + '" is already in the game.'
        @log.debug(message)
        return [message]
      end
      @log.debug('user "' + userName + '" has connected to game "' + gameName + '"')

      #postconditions and invariants
      _connectToGamePostconditions(gameName,userName)
      _invariants

      return ['', @gameSessions[gameName].gameType]
    end # no such game
    message = 'game "' + gameName + '" does not exist'
    @log.debug(message)
    return [message]
  end





  def _putPreconditions(gameName, column)
    begin
      assert(@gameSessions.has_key? gameName, 'given game name does not exist')
      assert(((@gameSessions[gameName].gameColumns > column) and (column >= 0)), 'column out of range')
    rescue
    end
  end

  def _putPostconditions
    # if we get here, the we know that put was called. Further contracts
    # are fulfilled in the game classes
  end

  # place a piece in the given column of the given game
  def put(gameName, column)

    #preconditions and invariants
    _invariants
    _putPreconditions(gameName, column)

    if @gameSessions[gameName].nPlayersPresent != 2
      return false
    end

    @log.debug('placing piece in game "' + gameName + '" in column ' + column.to_s)
    begin
      ret = @gameSessions[gameName].put(column)
      @log.debug('piece in game "' + gameName + '" in column ' + column.to_s + ' has been placed')

      #postconditions and invariants
      _putPostconditions
      _invariants

      return true#ret
    rescue
      @log.debug('something went wrong when placing piece in game "' + gameName + '" in column "' + column.to_s)
    end
    return false#[Game.UNKNOWN_EXCEPTION]
  end



  def _quitPreconditions(gameName,username)
    begin
      assert(@gameSessions.has_key? gameName, 'game not in session')
      assert(@gameSessions[gameName].players[username], 'given user not in session')
    rescue
    end
  end

  def _quitPostconditions(gameName,username)
    begin
      if @gameSessions.has_key? gameName
        assert_false(@gameSessions[gameName].players[username], 'given user is in session')
      else
        assert_equal(@_hostGamePreconditions_gameCount-1,gameCount,'game not removed')
      end
    rescue
    end
  end

  # quit the game
  def quit(gameName, username)

    #preconditions and invariants
    _quitPreconditions(gameName,username)
    _invariants

    @log.debug('player "' + username + '" is leaving game "' + gameName + '"')
    if @gameSessions[gameName].playerLeave(username)
      #@notify([OTHER_PLAYER_LEFT_TOKEN])
      @log.debug('player "' + username + '" has left game "' + gameName + '"')

      # postconditions and invariants
      _invariants
      _quitPostconditions(gameName,username)

      return true
    end
    @log.debug('something went wrong; player "' + username + '" could not leave game "' + gameName + '"')
    return false
  end



  def _savePreconditions(gameName)
    begin
      assert(@gameSessions.has_key? gameName, 'game not in session')
    rescue
    end
  end

  def _savePostconditions(gameName)
    begin
      assert_not_equal(@databaseProxy.loadGame(gameName), nil, 'game not saved in database')
    rescue
    end
  end

  # save the game for later
  def save(gameName)

    # preconditions and invariants
    _invariants
    _savePreconditions(gameName)

    @log.debug('saving game "' + gameName + '"')
    begin
      game = Marshal.dump(@gameSessions[gameName])
      @databaseProxy.saveGame(gameName,game)
      @log.debug('game "' + gameName + '" was saved')

      #post conditions and invariants
      _savePostconditions(gameName)
      _invariants

      return true
    rescue Mysql::Error => e
      @log.debug('game "' + gameName + '" could not be saved: ' + e.to_s)
      return false
    end
  end



  def _loadGamePreconditions
    begin
      assert_not_equal(@databaseProxy.loadGame(gameName), nil, 'game not saved in database')
      assert_false(@gameSessions.has_key? gameName, 'game already in session')
      assert(@gameSessions[gameName].players.has_key? userName, 'given user not in session')
    rescue
    end
  end

  def _loadGamePostconditions
    begin
      assert(@gameSessions.has_key? gameName, 'game not in session')
    rescue
    end
  end

  # load a saved game
  def loadGame(gameName, username)

    #preconditions and invariants
    _loadGamePreconditions
    _invariants

    @log.debug('trying to load game "' + gameName + '", with user "' + username + '" hosting')
    begin
      if gameCount >= @maxGames
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

    #postconditions and invariants
    _loadGamePostconditions
    _invariants

    return [@gameSessions[gameName].gameType,@gameSessions[gameName].hostUser]
  end


  # get a list of statistics for the overall "tournament"
  def getStats
    return @databaseProxy.getAllUserStats
  end

  # tell anyone listening that it's time to shut down the server
  def sendShutdownNotification
  end

  def gameCount
    @gameSessions.length
  end


  def _invariants
    begin
      assert(gameCount <= 5, 'too many games')
      assert(@gameSessions.length <= 5, 'too many games')
      @gameSessions.values.each {|s| assert(s.players.length <= 2, 'too many players') }
    rescue
    end
  end


end
