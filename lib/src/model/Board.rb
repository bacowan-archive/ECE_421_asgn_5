# the board representation. Essentially just a grid of pieces.
class Board
  def initialize(dims)
    @board = (0..dims[0]-1).collect { |i|
      (0..dims[1]-1).collect {0}
    }
  end

  def setBoard(board)
    @board = board
  end

  def getBoard
    return @board
  end

  def deep_copy
    newBoard = Board.new([getHeight,getWidth])

    newInternalBoard = (0..getHeight-1).collect { |i|
      (0..getWidth-1).collect {0}
    }

    (0..getHeight-1).each {|i|
      (0..getWidth-1).each {|j|
        newInternalBoard[i][j] = @board[i][j]
      }
    }

    newBoard.setBoard(newInternalBoard)

    return newBoard
  end

  # get the piece in a specific spot
  def [](x,y)
    return @board[x][y]
  end

  # put a piece in the given column. If the column is full, return false. Else,
  # return the row in which the piece was placed.
  def put(piece,column)
    firstEmpty = _firstEmptyRowOfColumn(column)
    if firstEmpty == nil
      return false
    end
    @board[firstEmpty][column] = piece
    return firstEmpty
  end

  # get the height of the board
  def getHeight
    return @board.length
  end

  # get the width of the board
  def getWidth
    return @board[0].length
  end

  # get the number of pieces in play
  def pieceCount
    return @board.collect {|i| i.select{|j| j != 0}.size}.inject{|sum,x| sum + x}
  end

  # return true if the board is full
  def full
    return !(0..@board[0].length-1).any? {|i| _firstEmptyRowOfColumn(i) != nil}
  end

  # return true if the given column is full
  # TODO: unit tests
  def columnFull(index)
    return _firstEmptyRowOfColumn(index) ? true : false
  end

  # display the board
  def to_s
    str = ''
    @board.each { |row|
      row.each {|col|
        str += col.to_s + ' '
      }
      str += "\n"
    }
    return str
  end

  # get the first empty row in the given column, or nil if there is none
  def _firstEmptyRowOfColumn(col)
    revVal = @board.reverse.find_index {|i| i[col] == 0}
    if revVal == nil
      return nil
    end
    return @board.length - 1 - revVal
  end

  def ==(other)
    if !other.is_a? Board
      return false
    end
    return other.getBoard == getBoard
  end

  def marshal_dump
    [@board]
  end

  def marshal_load(array)
    @board = array[0]
  end

end
