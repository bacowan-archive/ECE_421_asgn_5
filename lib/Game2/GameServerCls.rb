require 'xmlrpc/server'
require 'logger'
require 'thread'
require 'Game'
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

  trap "SIGINT" do
    @stopServerMutex.synchronize {
      @stopServer = true
    }
  end

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
    @log.level = Logger::WARN
    @stopServer = false
    @stopServerMutex = Mutex.new
    @databaseProxy = DatabaseProxy.new
  end

  def getNotification(gameName, notificationNum)
    notification = false
    while !notification and !@stopServer
      # poll for notificaion
      notification = @gameSessions[gameName].getNotification(notificationNum)
      sleep(1)
    end
    notification.each_with_index { |item, index|
      if item.is_a? Board
        notification[i] = notification[i].getBoard
      end
    }

    # If the game is over, we can remove the game from the sessions, and add to the statistics
    if notification[0] == Game.WIN_FLAG
      _winGame(gameName,notification[2])
    elsif notification[0] == Game.STALEMATE_FLAG
      _stalemate(gameName)
    end

    return notification
  end

  def hostGame(gameName,userName,gameType,dimensions)
    if @gameCount < @maxGames # start a new game
      begin
        @gameSessions[gameName] = GameProxy.new(gameName,gameType,dimensions)
        return @gameSessions[gameName].addPlayer(userName)
      rescue
        return false
      end
    end
    return false
  end

  # gameName: the name of the game to join
  # userName: the name of the user joining
  def connectToGame(gameName,userName)
    if @gameSessions.has_key?(gameName) # join the existing game
      if not @gameSessions[gameName].addPlayer(userName)
        return false
      end
    else # too many games
      return false
    end
    return true
  end

  def put(gameName, column)
    @gameSessions[gameName].put(column)
  end

  def quit(gameName, username)
    if @gameSessions[gameName].playerLeave(userName)
      notify([OTHER_PLAYER_LEFT_TOKEN])
      return true
    end
    return false
  end

  def save(gameName)
    game = Marshal.dump(@gameSessions[gameName])
    @databaseProxy.saveGame(gameName,game)
  end

  def loadGame(gameName, username)
    return false if @gameCount >= @maxGames
    game = @databaseProxy.loadGame(gameName)
    return false if game == nil
    @gameSessions[gameName] = Marshal.load(game)
    return @gameSessions[gameName].addUser(userName)
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
    otherPlayer = @gameSessions[gameName].players.keys.select {|user| user != winner} [0]
    @databaseProxy.addLoss(otherPlayer)
    @gameSessions.delete(gameName)
  end

  def _stalemate(gameName)
    @gameSessions[gameName].players.keys.each {|user| @databaseProxy.addTie(user)}
    @gameSessions.delete(gameName)
  end

end
