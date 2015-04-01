require 'xmlrpc/server'

DEFAULT_MAX_GAMES = 5
OTHER_PLAYER_LEFT_TOKEN = 'OTHER_PLAYER_LEFT_TOKEN'

class GameServerCls
  INTERFACE = XMLRPC::interface('game') {
    meth 'array getNotification(String)', 'get a notification from the server when the server has one', 'getNotification'
    meth 'array put(String, int)', 'put a piece (of the client) in the given column', 'put'
    meth 'boolean quit(String, String)', 'quit the game and disconnect from the server', 'quit'
    meth 'boolean save()', 'save the current game state', 'save'
    meth 'Map<String,[int,int]> getStats()', 'get the stats of the "tournament"', 'getStats'
    meth 'boolean connectToGame(String, String)', 'connect to the game of the first string, as the user of the second string', 'connectToGame'
    meth 'boolean hostGame(String, String, String, Array)', 'host a game as a user of the given string, and the game type of the third string'
    meth 'boolean loadGame(String, String)', 'load the game of the first string as the user of the second string', 'loadGame'
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
  end

  def getNotification(gameName)
    # TODO: non-blocking while we wait for a notification to appear
  end

  def hostGame(gameName,userName,gameType,dimensions)
    if @gameCount < @maxGames # start a new game
      begin
        @gameSessions[gameName] = GameProxy.new(gameName,gameType,dimensions)
        @gameSessions[gameName].addObserver(self)
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
  end

  # this is the listener for the board.
  def notify(*args)
    # TODO: forward notifications onto clients
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
    # TODO: marchael game
  end

  def loadGame(gameName, username)
    # TODO: this
  end

  def getStats
    # TODO: this
  end

end