class ColumnController

  def initialize(game)
    @game = game
  end

  # place a piece in the game, at the column of the given index.
  def clickColumn(index)
    @game.placePiece(index)
  end

  def gameReady
    @game.sendInitialNotification
  end

end
