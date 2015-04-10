require 'xmlrpc/server'
require 'logger'
require 'thread'
require_relative '../src/model/Game'
require_relative 'DatabaseProxy'
require_relative 'GameProxy'

DEFAULT_MAX_GAMES = 5
OTHER_PLAYER_LEFT_TOKEN = 'OTHER_PLAYER_LEFT_TOKEN'

class GameServerCls
  INTERFACE = XMLRPC::interface('game') {
    meth 'Array getNotification(String, int)', 'get a notification from the server when the server has one', 'getNotification'
    meth 'array put(String, int)', 'put a piece (of the client) in the given column', 'put'
    meth 'boolean quit(String, String)', 'quit the game and disconnect from the server', 'quit'
    meth 'boolean save()', 'save the current game state', 'save'
    meth 'Hash getStats()', 'get the stats of the "tournament"', 'getStats'
    meth 'boolean connectToGame(String, String)', 'connect to the game of the first string, as the user of the second string', 'connectToGame'
    meth 'boolean hostGame(String, String, String, Array)', 'host a game as a user of the given string, and the game type of the third string'
    meth 'boolean loadGame(String, String)', 'load the game of the first string as the user of the second string', 'loadGame'
  }

  #trap "SIGINT" do
  #  puts 'yay!'
  #end

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
    #@log.level = Logger::WARN
    @stopServer = false
    @stopServerMutex = Mutex.new
    @databaseProxy = DatabaseProxy.new
    @log.debug('server started')
  end

  def getNotification(gameName, notificationNum)
    @log.debug('getting ' + notificationNum.to_s + '\'st notification for ' + gameName)
    notification = false
    while !notification and !@stopServer
      # poll for notificaion
      notification = @gameSessions[gameName].getNotification(notificationNum)
      sleep(1)
    end

    @log.debug(notificationNum.to_s + '\'th notification for ' + gameName + 'is processing')

    notification.each_with_index { |item, index|
      if item.is_a? Board
        notification[index] = notification[index].getBoard
      end
    }
    # If the game is over, we can remove the game from the sessions, and add to the statistics
    if notification[0] == Game.WIN_FLAG
      _winGame(gameName,notification[2])
    elsif notification[0] == Game.STALEMATE_FLAG
      _stalemate(gameName)
    end

    @log.debug(notificationNum.to_s + '\'th notification for ' + gameName + 'is sending')

    return notification
  end

  def hostGame(gameName,userName,gameType,dimensions)
    @log.debug('hosting game ' + gameName + '. Host user: ' + userName + '. Game Type: ' + gameType + '. Dimensions: ' + dimensions.to_s)
    if @gameCount < @maxGames # start a new game
      begin
        @gameSessions[gameName] = GameProxy.new(gameName,gameType,dimensions)
        return @gameSessions[gameName].addPlayer(userName)
      rescue
        @log.debug('game creation step failed for game: ' + gameName + '. Host user: ' + userName + '. Game Type: ' + gameType + '. Dimensions: ' + dimensions.to_s)
        return false # TODO: make this a custom error
      end
    end
    @log.debug('cound not host game: ' + gameName + '. Limit for number of games on server met.')
    return false
  end

  # gameName: the name of the game to join
  # userName: the name of the user joining
  def connectToGame(gameName,userName)
    @log.debug('connecting to game: ' + gameName + ' as user: ' + userName)
    if @gameSessions.has_key?(gameName) # join the existing game
      if not @gameSessions[gameName].addPlayer(userName)
        @log.debug('game "' + gameName + '" is full, and user "' + userName + '" is not a part of the game')
        return false
      end
      @log.debug('user "' + userName + '" has connected to game "' + gameName + '"')
      return true
    end # no such game
    @log.debug('game "' + gameName + '" does not exist')
    return false
  end

  def put(gameName, column)
    @log.debug('placing piece in game "' + gameName + '" in column ' + column.to_s)
    begin
      return @gameSessions[gameName].put(column)
    rescue
      @log.debug('something went wrong when placing piece in game "' + gameName + '" in column "' + column.to_s)
    end
    return [Game.UNKNOWN_EXCEPTION]
  end

  def quit(gameName, username)
    @log.debug('player "' + username + '" is leaving game "' + gameName + '"')
    if @gameSessions[gameName].playerLeave(userName)
      notify([OTHER_PLAYER_LEFT_TOKEN])
      @log.debug('player "' + username + '" has left game "' + gameName + '"')
      return true
    end
    @log.debug('something went wrong; player "' + username + '" could not leave game "' + gameName + '"')
    return false
  end

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

  def loadGame(gameName, username)
    @log.debug('trying to load game "' + gameName + '", with user "' + username + '" hosting')
    begin
      if @gameCount >= @maxGames
        @log.debug('too many games already in session to load game "' + gameName + '"')
        return false
      end
      game = @databaseProxy.loadGame(gameName)
      if game == nil
        @log.debug('game "' + gameName + '" could not be loaded')
        return false
      end
      @gameSessions[gameName] = Marshal.load(game)
      @gameSessions[gameName].addPlayer(username)
    rescue Mysql::Error => e
      return false
      @log.debug('game "' + gameName + '" could not be loaded due to sql error: ' + e.to_s)
    end
    @log.debug('game "' + gameName + '" has been loaded with user "' + username + '" hosting')
    return true
  end

  def getStats
    return @databaseProxy.getAllUserStats
  end

  # tell anyone listening that it's time to shut down the server
  def sendShutdownNotification
  end

  # this is the listener for the board.
  #def notify(*args)
  #  # TODO: forward notifications onto clients, and if notification is that the game has finished, add to the database
  #  puts args
  #  #@log.debug(args)
  #end

  def _winGame(gameName,winner)
    @databaseProxy.addWin(winner)
    otherPlayer = @gameSessions[gameName].players.keys.select {|user| user != winner}
    @databaseProxy.addLoss(otherPlayer[0])
    @gameSessions.delete(gameName)
  end

  def _stalemate(gameName)
    @gameSessions[gameName].players.keys.each {|user| @databaseProxy.addTie(user)}
    @gameSessions.delete(gameName)
  end

end
