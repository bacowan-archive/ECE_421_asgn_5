require_relative '../model/GameFactory'
require_relative '../controller/ColumnController'
require_relative '../model/Game'
require_relative '../model/AIFactory'

class IngameCommandLineInterface

  def initialize(game, player1AI, player2AI, player1Piece, player2Piece, dimensions)
    gameFactory = GameFactory.new
    game = gameFactory.createGame(game,player1Piece,player2Piece,dimensions)
    @gameController = ColumnController.new(game)
    aiFactory = AIFactory.new
    aiFactory.createAI(player1AI,game.winCondition,player1Piece,player2Piece,@gameController,game)
    aiFactory.createAI(player2AI,game.winCondition,player2Piece,player1Piece,@gameController,game)
    game.addObserver(self)
    @currentTurn = game.turn
    @boardState = game.board
    @gameName = game.gameName
    @win = false
  end

  # start the game
  def start
    # continuously get input from the user
    continue = true
    commands = _initializeCommands
    @gameController.gameReady
    while continue and not @win
      fullCommand = _parseCommand(_getCommand)
      if commands.has_key? fullCommand[0]
        begin
          continue = commands[fullCommand[0]].call(*fullCommand[1..-1])
        rescue ArgumentError
          puts 'wrong number of arguments'
        end
      elsif fullCommand.length != 0
        continue = fullCommand[0] + ' is not a valid command'
      end

      if continue.is_a? String
        puts continue # display any error messages
      end
    end
  end

  # create a list of valid commands mapped to their respective functions
  def _initializeCommands
    commands = Hash.new
    commands['exit'] = lambda{_exitCommand}
    commands['display'] = lambda{_displayCommand}
    commands['turn'] = lambda{_turnCommand}
    commands['put'] = lambda{|x| _putCommand(x)}
    commands['help'] = lambda{_helpCommand}
    return commands
  end

  # display prompt and get the command from the user
  def _getCommand
    print @gameName + ' >> '
    return gets
  end

  # parse a command into its components
  def _parseCommand(command)
    command.split
  end

  # quit the game
  def _exitCommand
    return false
  end

  # display the current board state
  def _displayCommand
    puts @boardState.to_s
    return true
  end

  # display whose turn it is
  def _turnCommand
    puts @currentTurn
    return true
  end

  # put down a piece
  def _putCommand(column)
    begin
      Integer(column)
    rescue
      return 'argument needs to be an integer'
    end

    @gameController.clickColumn(Integer(column))

    return true

  end

  def _helpCommand
    return "Commands:\nexit: exit the current game\ndisplay: display the game board\nturn: display whose turn it currently is\nput <column>: place a piece in a column\nhelp: display this help message"
  end

  # do this whenever the game state changes
  def notify(*args)
    if args[0] == Game.CHANGE_TURN_FLAG
      @boardState = args[1]
      @currentTurn = args[2]
      puts @boardState.to_s
      puts 'player ' + @currentTurn.to_s + '\'s turn'
    elsif args[0] == Game.WIN_FLAG
      puts @boardState.to_s
      puts 'player ' + args[2] + ' wins'
      @win = true
    elsif args[0] == Game.STALEMATE_FLAG
      puts 'stalemate'
      @win = true
    elsif args[0] == Game.COLUMN_FULL_FLAG
      puts 'that column is full or does not exist.'
    elsif args[0] == Game.UNKNOWN_EXCEPTION
      puts 'uh-oh, something broke. Sorry, the game will end.'
      @win = true
    end
  end


end