class WinCondition

  # p1 and p2 are tokens for player 1 and 2. winCondition is the specific WinCondition
  def initialize(p1,p2,winCondition)
    @winCondition = winCondition
    @p1 = p1
    @p2 = p2
  end

  def getName
    @winCondition.getName
  end

  # if the win condition has been met, return false. Otherwise, return the user
  # who wins.
  # input:
  #   board: the state of the game
  #   row: the row where the newest piece was placed
  #   col: the column where the newest piece was placed
  def win(board,row,col)
    operations = [[:+,nil],[nil,:+],[:+,:+],[:+,:-]] # the four directions to win
    winVal = false
    anyWin = operations.any? {|i|
      winVal = _axisWin(board,row,col,i[0],i[1])
    }
    if anyWin
      return winVal
    end
    return false

  end

  # check if the given value is inbounds or not. True for row, and false for column
  def _inbounds(val,rowCol,board)
    if rowCol
      return (val >=0 and val < board.getWidth)
    end
    return (val >= 0 and val < board.getHeight)
  end

  # see if the win condition is met on the given axis (vertical, horizontal,
  # or one of the two diagonals). HorizontalOperation and verticalOperation
  # should be either :+, :-, or nil, indicating what way will check on the axes.
  # A line will be checked with a slope equal to horizontalOperation/verticalOperation
  # (where nil is 0, + is one, and - is -1)
  # For example, if horizontal is + and vertical is nil, we will check the
  # horizontal axis. If horizontal is + and vertical is -, we will check a
  # diagonal going down and right.
  def _axisWin(board,row,col,horizontalOperation,verticalOperation)
    # start on the far side, and make its way to the other side
    winVal = false
    (0..3).find {|i|
      x = verticalOperation == nil ? row : row.send(verticalOperation,i)
      y = horizontalOperation == nil ? col : col.send(horizontalOperation,i)
      items = (0..3).collect {|j|
        xMinus = verticalOperation == nil ? x : x - 0.send(verticalOperation,j)
        yMinus = horizontalOperation == nil ? y : y - 0.send(horizontalOperation,j)
        if !_inbounds(xMinus,false,board) or !_inbounds(yMinus,true,board)
          false
        else
          board[xMinus, yMinus]
        end
      }
      winner = _checkCondition(items)
      if winner
        winVal = winner
        true
      end
    }
    return winVal
  end

  def _checkCondition(items)
    return @winCondition.checkCondition(items,@p1,@p2)
  end

  def marshal_dump
    [@winCondition, @p1, @p2]
  end

  def marshal_load(array)
    @winCondition, @p1, @p2 = array
  end

end
