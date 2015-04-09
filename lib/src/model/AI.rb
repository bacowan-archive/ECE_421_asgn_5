require_relative 'Game'

class AI

  def initialize(logic,playerId,columnController)
    @logic = logic
    @id = playerId
    @columnController = columnController
  end

  def notify(*args)
    if args[0] == Game.CHANGE_TURN_FLAG and @id == args[2] # if it's the ai's turn, play the piece
      @columnController.clickColumn(@logic.nextMove(args[1]))
    end
  end

  def AI.getValidMoves(board)
    (0..board.getWidth-1).select {|i| board.columnFull(i)}
  end

end