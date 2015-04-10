require 'gtk2'
require_relative 'GameBoard.rb'
require_relative '../view/Host_Screen.rb'
require_relative '../../Game2/GameClientObjController.rb'
require_relative '../view/MultiplayerGameBoard.rb'
require_relative '../view/StatScreen.rb'

class GameMenu

  def initialize

	@gameName = "myGame"
	@userName = "Iplayer"
	@host = ENV['HOSTNAME']  
	@path = '/RPC2'
	@port = GameServer.DEFAULT_PORT
	@client = GameClientObjController.new(@host,@path,@port)
	@choices = nil

# Initialize
    Gtk.init
    @builder = Gtk::Builder::new
    @builder.add_from_file("./lib/src/view/Game_Select_Screen.glade")
    

#
# Step 1: get the window to terminate the program when it's destroyed
#
    window = @builder.get_object("window1")
    window.signal_connect( "destroy" ) { Gtk.main_quit }

# Step 2: get the exit button to terminate the program when it's activated
    exit_button = @builder.get_object("button2")
    exit_button.signal_connect("clicked"){window.destroy}

# Step 3: get the start button to begin the game
    start_button = @builder.get_object("button1")
    start_button.signal_connect("clicked"){
		
	start_game
	
		
    }

# Step 4: get the Host Game Button
	host_button = @builder.get_object("button3")
	host_button.signal_connect("clicked"){

		host_game
			
	}

# Step 5: get the Join Game Button
	join_button = @builder.get_object("button4")
	join_button.signal_connect("clicked"){

		join_game
		
	}

# Step 5: load Game Button
	load_button = @builder.get_object("button5")
	load_button.signal_connect("clicked"){
		load_game
		
		
	}

# Step 6: stats Button
	stat_button = @builder.get_object("button6")
	stat_button.signal_connect("clicked"){
		stats
		
		
	}


    window.show()
    Gtk.main()
  end
	def start_game
		getChoices()
		new_game = GameBoard.new(@choices)	
	end 

	def resume
		@builder.get_object("window1").show
	end

	def host_game
		getChoices()
		screen = HostScreen.new(self)
		if @choices[0] == "Connect4"
			gameType = ConnectFourWinCondition.name
		else
			gameType = OttoTootWinCondition.name
		end
		ret = @client.hostGame(@gameName,@userName,gameType,[6,7])
		if ret == true
			new_game = MultiplayerGameBoard.new(@client, @choices, @gameName, @userName, 1)
		else
			puts "Failed to Connect\n"
		end
	end

	def join_game
		getChoices()
		screen = HostScreen.new(self)
		@client.connectToGame(@gameName,@userName)
		new_game = MultiplayerGameBoard.new(@client, @choices, @gameName, @userName, 2)
	end

	def load_game
		getChoices()
		screen = HostScreen.new(self)
		@choices[0] = @client.loadGame(@gameName, @username)
		new_game = MultiplayerGameBoard.new(@client,@choices,@gameName,@userName)
	end

	def stats
		screen = StatScreen.new(@client)	
	end

	def setNames(gameName, userName)
		@gameName = gameName
		@userName = userName
	end

	def getChoices()
		@choices = (1..5).collect{|i| @builder.get_object("combobox" + i.to_s).active_text}
	end

end
