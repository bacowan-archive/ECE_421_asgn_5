class OttoTootWinCondition

  def OttoTootWinCondition.name
    'OTTO_TOOT'
  end

  def checkCondition(items,p1,p2)
    if items[0] == p1 and items[1] == p2 and items[2] == p2 and items[3] == p1
      return p1
    elsif items[0] == p2 and items[1] == p1 and items[2] == p1 and items[3] == p2
      return p2
    end
    return false
  end

end