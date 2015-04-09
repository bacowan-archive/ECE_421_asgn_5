class ConnectFourWinCondition

  def ConnectFourWinCondition.name
    'CONNECT_FOUR'
  end

  def checkCondition(items,p1,p2)
    if items.all? {|x| x == p1}
      return p1
    elsif items.all? {|x| x == p2}
      return p2
    end
    return false
  end

end