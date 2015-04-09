require 'gtk2'
require_relative 'GameBoard.rb'
require_relative '../view/Host_Screen.rb'

class GameMenu

  def initialize

	@gameName = "myGame"
	@userName = "Iplayer"

# Initialize
    Gtk.init
    @builder = Gtk::Builder::new
    @builder.add_from_file("./lib/src/view/Game_Select_Screen.glade")
    @server = XMLRPC::Client.new(ENV['HOSTNAME'], '/RPC2', GameServer.DEFAULT_PORT)

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
	window.destroy
		
    }

# Step 4: get the Host Game Button
	host_button = @builder.get_object("button3")
	host_button.signal_connect("clicked"){

		host_game
		window.destroy	
	}

# Step 5: get the Join Game Button
	join_button = @builder.get_object("button4")
	join_button.signal_connect("clicked"){

		join_game
		window.destroy
	}

# Step 5: load Game Button


    window.show()
    Gtk.main()
  end
	def start_game
		#Get Choices
		choices = (1..5).collect{|i| @builder.get_object("combobox" + i.to_s).active_text}
		new_game = GameBoard.new(choices)
			
	end 
	def resume
		@builder.get_object("window1").show
	end

	def host_game
		#Get Choices
		choices = (1..5).collect{|i| @builder.get_object("combobox" + i.to_s).active_text}
		client = GameClientObjController.new(@server)
		screen = HostScreen.new(self)
		if choices[0] == "Connect4"
			gameType = ConnectFourWinCondition.name
		else
			gameType = OttoTootWinCondition.name
		end
		client.hostGame(@gameName,@userName,gameType,[6,7])
		new_game = MultiplayerGameBoard.new(client, choices, @gameName, @userName)
		
	end

	def join_game
		#Get Choices
		choices = (1..5).collect{|i| @builder.get_object("combobox" + i.to_s).active_text}
		client = GameClientObjController.new(@server)
	end

	def load_game
		client= GameClientObjController.new(@server)
		client.load(gameName, username)
		new_game = Maul
	end

	def setNames(gameName, userName)
		@gameName = gameName
		@userName = userName
	end

end
