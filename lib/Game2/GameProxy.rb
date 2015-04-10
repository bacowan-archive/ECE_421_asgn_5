# information about a game connection, including the game name
# and the players in the game

require 'src/model/GameFactory'

PLAYER_1_PIECE = '1'
PLAYER_2_PIECE = '2'

class GameProxy
  def initialize(name,gameType,dimensions,notificationCacheSize=5)
    #@observers = []
    @players = Hash.new # player names mapped to boolean indicating if they have joined or not
    @notifications = Hash.new # a list of notifications to send. Keyed on notification number, valued on the notification itself
    @notificationCacheSize = notificationCacheSize
    @notificationCount = 0
    factory = GameFactory.new
    begin
      @game = factory.createGame(gameType,PLAYER_1_PIECE,PLAYER_2_PIECE,dimensions)
    rescue # TODO: set factory to raise a custom exception when gameType is invalid
      raise 'game type ' + gameType + ' is not valid'
    end
    @game.addObserver(self)
  end

  def players
    return @players
  end

  def notify(*args)
    @notifications[@notificationCount] = args
    if @notifications.size > @notificationCacheSize
      @notifications.delete(@notifications.keys.min)
    end
    @notificationCount += 1
  end

  def getNotification(index)
    if @notifications.keys.min > index
      #TODO raise an error
    end
    if @notifications.has_key? index
      return @notifications[index]
    end
    return false
  end

  # add a player name to the game and return true. If there are already
  # too many players, or that player has already joined, return false.
  def addPlayer(playerName)
    if (!@players.has_key?(playerName) and @players.length > 1) or (@players.has_key?(playerName) and @players[playerName])
      return false
    end
    @players[playerName] = true
    _canStart
    return true
  end

  # indicate that a player has left the game.
  def playerLeave(playerName)
    if @players.has_key?(playerName)
      @players[playerName] = false
      return true
    end
    return false
  end

  # add a notification to the queue
  def newNotification(note)
    @notification = note
  end

  def retrieveNotification
    if @notification == nil
      return false
    end
    ret = @notification
    @notification = nil
    return ret
  end

  def put(col)
    if _allPlayersPresent
      @game.placePiece(col)
    end
  end

  # if we can start the game (all players are there), send out the initial notification
  def _canStart
    if _allPlayersPresent
      @game.sendInitialNotification
    end
  end

  def _allPlayersPresent
    @players.values.all? {|p| p }
  end

  def marshal_dump
    [@players.keys,@game,@notifications,@notificationCacheSize,@notificationCount]
  end

  def marshal_load(array)
    keys, @game, @notifications, @notificationCacheSize, @notificationCount = array
    @players = Hash.new
    keys[0].each {|k| @players[k] = false}
    @game.addObserver(self)
  end


end
