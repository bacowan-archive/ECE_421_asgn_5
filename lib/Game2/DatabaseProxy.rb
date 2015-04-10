require 'mysql'

DB_URL = 'mysqlsrv.ece.ualberta.ca'
DB_USERNAME = 'ece421usr1'
DB_PASSWORD = 'a421Prs0n'
DB_NAME = 'ece421grp1'
DB_PORT = 13020

TABLE_NAME = 'stats'
USER_COLUMN = 'user'
WINS_COLUMN = 'wins'
LOSSES_COLUMN = 'losses'
TIES_COLUMN = 'ties'

SAVED_GAMES_TABLE_NAME = 'saved_games'
GAME_NAME_COLUMN = 'game_name'
GAME_COLUMN = 'game'

class DatabaseProxy
  def initialize
    @db = Mysql.new(DB_URL,DB_USERNAME,DB_PASSWORD,DB_NAME,DB_PORT)
    _initializeDatabase
  end

  def _initializeDatabase
    @db.query('CREATE TABLE IF NOT EXISTS ' + TABLE_NAME +
      '(' + USER_COLUMN + ' CHAR(40) NOT NULL, ' +
      WINS_COLUMN + ' int NOT NULL, ' +
      LOSSES_COLUMN + ' int NOT NULL, ' +
      TIES_COLUMN + ' int NOT NULL, ' +
      'PRIMARY KEY (' + USER_COLUMN + '))')
    @db.query('CREATE TABLE IF NOT EXISTS ' + SAVED_GAMES_TABLE_NAME +
      ' (' + GAME_NAME_COLUMN + ' CHAR(40) NOT NULL, ' +
      GAME_COLUMN + ' BLOB NOT NULL, ' +
      'PRIMARY KEY (' + GAME_NAME_COLUMN + '))')
  end

  def _deleteDatabase
    @db.query('DROP TABLE ' + TABLE_NAME)
    @db.query('DROP TABLE ' + SAVED_GAMES_TABLE_NAME)
  end

  def addWin(username)
    _addUser(username)
    _addToColumn(username,WINS_COLUMN)
  end

  def addLoss(username)
    _addUser(username)
    _addToColumn(username,LOSSES_COLUMN)
  end

  def addTie(username)
    _addUser(username)
    _addToColumn(username,TIES_COLUMN)
  end

  def getUserStats(username)
    return @db.query('SELECT * FROM ' + TABLE_NAME + ' WHERE ' +
      USER_COLUMN + "='" + username + "'").fetch_row
  end

  def getAllUserStats
    stats = @db.query('SELECT * FROM ' + TABLE_NAME)
    numRows = stats.num_rows
    ret = []
    numRows.times {
      ret << stats.fetch_row
    }
    return ret
  end

  def resetDatabase
    _deleteDatabase
    _initializeDatabase
  end

  def saveGame(gameName,game)
    @db.query('INSERT INTO ' + SAVED_GAMES_TABLE_NAME + " (" + GAME_NAME_COLUMN + ", " + GAME_COLUMN + ") VALUES ('" + gameName + "', '" + game + "')")
  end

  def loadGame(gameName)
    ret = @db.query('SELECT ' + GAME_COLUMN + " FROM " + SAVED_GAMES_TABLE_NAME + " WHERE " +
      GAME_NAME_COLUMN + " = '" + gameName + "'").fetch_row
    @db.query("DELETE FROM " + SAVED_GAMES_TABLE_NAME + " WHERE " + GAME_NAME_COLUMN + "='" + gameName + "'")
    return ret[0]
  end

  def _addToColumn(username,col)
    @db.query('UPDATE ' + TABLE_NAME + " SET " + col + " = " + col + " + 1 WHERE " + USER_COLUMN + " = '" + username + "'")
  end

  def _addUser(username)
    begin
      @db.query('INSERT INTO ' + TABLE_NAME + ' (' + USER_COLUMN + ',' + WINS_COLUMN + ',' + LOSSES_COLUMN + ',' + TIES_COLUMN + ') ' +
        "VALUES ('" + username + "',0,0,0)")
    rescue Mysql::Error => e
      # this happens if the user already exists, which is fine
    end
    #@db.query('IF NOT EXISTS (SELECT * FROM ' + TABLE_NAME + ' u ' +
    #  'WHERE u.' + USER_COLUMN + "='" + username + "') " +
    #  'BEGIN ' +
    #  'INSERT INTO ' + TABLE_NAME + ' (' + USER_COLUMN + ',' + WINS_COLUMN + ',' + LOSSES_COLUMN + ',' + TIES_COLUMN + ') ' +
    #  "VALUES ('" + username + "',0,0,0)")
  end

end
