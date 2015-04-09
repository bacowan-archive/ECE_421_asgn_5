# this AI looks ahead 3 turns to see if it can win
class MediumAI

  def initialize(id,otherId,winCondition)
    @playerId = id
    @otherId = otherId
    @winCondition = winCondition
  end

  def nextMove(board)
    # find all valid moves
    legalMoves = (0..board.getWidth-1).select {|i| board.columnFull(i)}

    # make sure we don't mess with the actual board
    newBoard = board.clone


  end

  # look ahead in the game nMoreTimes turns. If the game can be won this turn, return the [true,winingColumn].
  # Otherwise, return [false,columnWithBestChances,NumberOfWinningMovesForThatColumn]
  def _lookAhead(board,nMoreTimes)

    validMoves = AI.getValidMoves(board)

    if nMoreTimes == 0
      return [false,validMoves[0],0]
    end

    # an even number means it is the opponent's turn, an odd number means it is
    # this user's turn
    if nMoreTimes % 2 == 0

    end

    # see how each of the possible moves fairs
    possibilities = validMoves.collect { |i|
      nextBoard = board.clone
      row = nextBoard.put(@playerId,i)
      win = @winCondition.win(board,row,i)
      if win
        [true,i]
      else
        [false,i,_lookAhead(nextBoard,nMoreTimes-1)[2]]
      end
    }

    # see if there were any winning moves
    winningMove = possibilities.index { |i| i[0] }
    if winningMove != nil
      return [true, possibilities[winningMove]]
    end
    # otherwise, give the best move, and how good it is

    return [false, ]

  end

end