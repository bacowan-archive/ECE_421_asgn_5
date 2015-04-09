# this AI looks ahead 3 turns to see if it can win
class AILogic

  WIN_TOKEN = 'win'
  LOSE_TOKEN = 'lose'
  NEITHER_TOKEN = 'neither'

  def initialize(id,otherId,winCondition,lookAheadCount)
    @playerId = id
    @otherId = otherId
    @winCondition = winCondition
    @lookAheadCount = lookAheadCount
  end

  def nextMove(board)
     _lookAhead(board,@lookAheadCount)[1]
  end

  def _lookAhead(board,nMoreTimes)
    options = AI.getValidMoves(board).collect {|col|
      _lookAheadOneMove(col,board,nMoreTimes,false)
    }
    return _selectBestColumn(options)
  end

  # look ahead in the game nMoreTimes turns. If the game can be won this turn, return the [true,winingColumn].
  # Otherwise, return [false,columnWithBestChances,NumberOfWinningMovesForThatColumn,NumberOfLosingMovesForThatColumn]
  def _lookAheadOneMove(col,board,nMoreTimes,opponent)
    

    # stopping condition
    if nMoreTimes < 1
      return [NEITHER_TOKEN,col,0,0]
    end
    # don't mess with the actual board
    newBoard = board.deep_copy
    row = newBoard.put(opponent ? @otherId : @playerId,col)
    if row == false
      return [NEITHER_TOKEN,col,0,0]
    end

    # if we will win or lose this turn
    winConditionMet = @winCondition.win(newBoard,row,col)
    if winConditionMet == @playerId
      return [WIN_TOKEN,col,opponent ? 1 : 0, opponent ? 0 : 1]
    elsif winConditionMet == @otherId
      return [LOSE_TOKEN,col,opponent ? 0 : 1, opponent ? 1 : 0]
    end

    # otherwise, analyze the next turn's options
    options = AI.getValidMoves(newBoard).collect {|nextCol|
      _lookAheadOneMove(nextCol,newBoard,nMoreTimes-1,!opponent)
    }

    if opponent
      return _selectBestColumn(options)
    end

    return _selectWorstColumn(options)

  end

  def _selectBestColumn(options)
    return _selectAColumn(options,WIN_TOKEN,LOSE_TOKEN)
  end

  def _selectWorstColumn(options)
    return _selectAColumn(options,LOSE_TOKEN,WIN_TOKEN)
  end

  def _selectAColumn(options,win,lose)
    best = nil
    options.each {|o|
      if best == nil
        best = o
      elsif o[0] == win
        best = o
      elsif o[0] == NEITHER_TOKEN
        if best[0] == NEITHER_TOKEN and o[2]-o[3] > best[2]-best[3]
          best = o
        end
      end
    }

    # if there are multiple equally as good options, randomly select one
    bestOptions = options.select {|o| o[0] == best[0] and o[2]-o[3] == best[2]-best[3]}
    if bestOptions.length > 1
      best = bestOptions.sample
    end
    totalWinningMoves = options.transpose[2].inject(:+)
    totalLosingMoves = options.transpose[3].inject(:+)


    return [best[0],best[1],totalWinningMoves,totalLosingMoves]
  end

  def marshal_dump
  [@playerId,@otherId,@winCondition,@lookAheadCount]
  end

  def marshal_load(array)
  @playerId,@otherId,@winCondition,@lookAheadCount = array
  end

end
