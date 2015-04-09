require_relative '../model/ConnectFourWinCondition'
require_relative '../model/OttoTootWinCondition'
require_relative 'IngameCommandLineInterface'

class CommandLineInterface

  VALID_GAMES = [ConnectFourWinCondition.name,OttoTootWinCondition.name]
  PLAYERS = ['1','2']
  AI_LEVELS = ['1','2','3']
  GAME_DIMENSIONS = [6,7]

  def initialize

    @game = ConnectFourWinCondition.name
    @players = Hash.new
    PLAYERS.each {|p|
      @players[p] = Hash[[ ['ai',false],['aiLevel',1] ]]
    }
  end

  # start the interface
  def start

    # continuously get input from the user
    continue = true
    commands = _initializeCommands
    while continue
      fullCommand = _parseCommand(_getCommand)
      if commands.has_key? fullCommand[0]
        begin
          continue = commands[fullCommand[0]].call(*fullCommand[1..-1])
        rescue ArgumentError
          puts 'wrong number of arguments'
        end
      else
        continue = fullCommand[0] + ' is not a valid command'
      end

      if continue.is_a? String
        puts continue # display any error messages
      end
    end
  end

  # create a list of valid commands mapped to the function they preform
  def _initializeCommands
    commands = Hash.new
    commands['exit'] = lambda{ _exitProgramCommand}
    commands['game'] = lambda{|x| _gameSelectCommand(x)}
    commands['player'] = lambda{|x,y| _playerSelectCommand(x,y)}
    commands['ai'] = lambda{|x,y| _aiSetCommand(x,y)}
    commands['start'] = lambda{_startCommand}
    commands['help'] = lambda{_helpCommand}
    return commands
  end

  # display prompt and get the command from the user
  def _getCommand
    print '>> '
    return gets
  end

  # parse a command into its components
  def _parseCommand(command)
    command.split
  end

  # command for exiting the program
  def _exitProgramCommand
    false
  end

  # select the game to play
  def _gameSelectCommand(name)
    if !VALID_GAMES.include? name
      return name + ' is not a valid game'
    end
    @game = name
    true
  end

  # set a player to be HUMAN or CPU
  def _playerSelectCommand(player,ai)

    if !PLAYERS.include? player
      return 'player ' + player + ' is invalid'
    end

    if ai == 'ai'
      ai = true
    elsif ai == 'human'
      ai = false
    else
      return 'must be either ai or cpu'
    end

    @players[player]['ai'] = ai
    true

  end

  # set the level of the ai
  def _aiSetCommand(player,level)

    if !PLAYERS.include? player
      return 'player ' + player + ' is invalid'
    end

    if !AI_LEVELS.include? level
      return level + ' is not a valid ai level'
    end

    @players[player]['aiLevel'] = level.to_i
    true

  end

  # start the game
  def _startCommand
    if @game == nil
      return 'you must first select a game'
    end

    p1Ai = false
    if @players['1']['ai'] == true
      p1Ai = @players['1']['aiLevel']
    end
    p2Ai = false
    if @players['2']['ai'] == true
      p2Ai = @players['2']['aiLevel']
    end

    game = IngameCommandLineInterface.new(@game,p1Ai,p2Ai,'1','2',GAME_DIMENSIONS)
    game.start
    puts 'game has finished'
    true
  end

  # display a message with the valid commands
  def _helpCommand
    return "Commands:\nexit: exit the program\ngame <name of game>: choose the game to play (OTTO_TOOT or CONNECT_FOUR)\nplayer <id> <\"ai\" or \"human\">: set player \"id\" to be either a human or computer player\nai <id> <1 2 or 3>: set the AI of player \"id\"\nstart: start the game"
  end

end