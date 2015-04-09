# this AI simply plays random valid moves
class EasyAI

  def initialize(id,winCondition)
    @playerId = id
    @winCondition = winCondition
  end

  def nextMove(board)
    # find all valid moves
    legalMoves = AI.getValidMoves(board)
    return legalMoves.sample
  end
end