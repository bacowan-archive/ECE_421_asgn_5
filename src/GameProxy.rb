# information about a game connection, including the game name
# and the players in the game

require 'src/Model/GameFactory'

PLAYER_1_PIECE = '1'
PLAYER_2_PIECE = '2'

class GameProxy
  def initialize(name,gameType,dimensions)
    @players = Hash.new # player names mapped to boolean indicating if they have joined or not
    @notification = nil # a list of notifications to send. TODO: Should put in a semaphore whenever I use. (if I even need a queue?)
    factory = GameFactory.new
    begin
      @game = factory.createGame(gameType,PLAYER_1_PIECE,PLAYER_2_PIECE,dimensions)
    rescue # TODO: set factory to raise a custom exception when gameType is invalid
      raise 'game type ' + gameType + ' is not valid'
    end
  end

  # add an observer to the game
  def addObserver(observer)
    @game.addObserver(observer)
  end

  # add a player name to the game and return true. If there are already
  # too many players, or that player has already joined, return false.
  def addPlayer(playerName)
    if @players.length > 2 or not @players.has_key?(playerName) or not @players[playerName]
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
    @player.values.all? {|p| p }
  end


end