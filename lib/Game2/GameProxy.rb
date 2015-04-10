# information about a game connection, including the game name
# and the players in the game

require 'src/model/GameFactory'

PLAYER_1_PIECE = 1
PLAYER_2_PIECE = 2

class GameProxy
  def initialize(name,gameType,dimensions,databaseProxy,logger,notificationCacheSize=5)
    #@observers = []
    @hostUser = ''
    @name = name
    @players = Hash.new # player names mapped to boolean indicating if they have joined or not
    @notifications = Hash.new # a list of notifications to send. Keyed on notification number, valued on the notification itself
    @notificationCacheSize = notificationCacheSize
    @notificationCount = 0
    @databaseProxy = databaseProxy
    @log = logger
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

  def gameType
    @game.winCondition.getName
  end

  def hostUser
    @hostUser
  end

  def notify(*args)
    @notifications[@notificationCount] = args
    if @notifications.size > @notificationCacheSize
      @notifications.delete(@notifications.keys.min)
    end
    @notificationCount += 1


    if args[0] == Game.WIN_FLAG
      _winGame(args[2])
    elsif args[0] == Game.STALEMATE_FLAG
      _stalemate
    end

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

  def _winGame(winner)
    @log.debug('player "' + winner.to_s + '" has won game "' + @name.to_s + '"')
    @databaseProxy.addWin(winner)
    otherPlayer = players.keys.select {|user| user != winner}
    @databaseProxy.addLoss(otherPlayer[0])
  end

  def _stalemate
    players.keys.each {|user| @databaseProxy.addTie(user)}
  end

  # add a player name to the game and return true. If there are already
  # too many players, or that player has already joined, return false.
  def addPlayer(playerName)
    if (!@players.has_key?(playerName) and @players.length > 1) or (@players.has_key?(playerName) and @players[playerName])
      return false
    end
    @players[playerName] = true
    # the first player to join is the host
    if @players.length == 1
      @hostUser = playerName
    end
    _canStart
    @game.sendInitialNotification
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
    #if _allPlayersPresent
      #@game.sendInitialNotification
    #end
  end

  def _allPlayersPresent
    @players.values.all? {|p| p }
  end

  def nPlayersPresent
    @players.values.count {|p| p}
  end

  def marshal_dump
    if @notificationCount = 0
      cnt = 0
    else
      cnt = 1
    end
    [@players.keys,@game,@notifications,@notificationCacheSize,cnt,@hostUser]
  end

  def marshal_load(array)
    keys, @game, notifications, @notificationCacheSize, @notificationCount, @hostUser = array
    # reset the notifications (only store the latest one)
    if notifications.length > 0
      lastNotification = notifications[notifications.keys.max]
      @notifications = Hash.new
      @notifications[0] = lastNotification
    else
      @notifications = Hash.new
    end
    @players = Hash.new
    keys.each {|k| @players[k] = false}
    @game.addObserver(self)
  end


end
