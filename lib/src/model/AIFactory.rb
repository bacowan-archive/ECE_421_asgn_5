require_relative 'AILogic'
require_relative 'AI'

class AIFactory

  # aiLevel: the difficulty level: 1-3
  def createAI(aiLevel,winCondition,player,opponent,columnController,game)

    if aiLevel == false
      return false
    end

    if aiLevel == 1
      logic = AILogic.new(player,opponent,winCondition,0)
    elsif aiLevel == 2
      logic = AILogic.new(player,opponent,winCondition,2)
    elsif aiLevel == 3
      logic = AILogic.new(player,opponent,winCondition,4)
    else
      return false
    end

    ai = AI.new(logic,player,columnController)

    # make sure the ais know what's going on in the game
    game.addAIObserver(ai)

  end

end
