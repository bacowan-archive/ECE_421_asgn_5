require 'gtk2'
require_relative '../model/GameFactory.rb'
require_relative '../controller/ColumnController.rb'
require_relative '../model/ConnectFourWinCondition.rb'
require_relative '../model/OttoTootWinCondition.rb'
require_relative '../model/AIFactory.rb'


class MultiplayerGameBoard
	def initialize(client, choices, gameName, userName)
	 @client = client
	 @client.setView(self)
	 @gameName = gameName
	 @userName = userName
	
#get inputs from the select menu
	@win = 0
	if choices[0] == "Connect4"
		gameType = ConnectFourWinCondition.name
		player1Piece = "Red"
		player2Piece = "Yellow"
		@image_map = {0=>"./lib/src/view/Empty_Grid.png",
				 player1Piece=>"./lib/src/view/Red_Grid.png",
				 player2Piece=>"./lib/src/view/Yellow_Grid.png"}
		
	else
		gameType = OttoTootWinCondition.name
		player1Piece = "O"
		player2Piece = "T"
		@image_map = {0=>"./lib/src/view/Empty_Grid.png",
				 player1Piece=>"./lib/src/view/O_Grid.png",
				 player2Piece=>"./lib/src/view/T_Grid.png"}
		
	end
#IN MULTIPLAYER TWO HUMANS PLAY
	diff_map = {"Easy"=>1,"Medium"=>2,"Hard"=>3}
	
	#if choices[1] == "Computer"
	#	player1AI = diff_map[choices[3]]
	#else
		player1AI = false
	#end

	#if choices[2] == "Computer"
	#	player2AI = diff_map[choices[4]]
	#else
		player2AI = false
	#end
	
	
# Setup the AI
	#aiFactory = AIFactory.new
	#aiFactory.createAI(player1AI,@game.winCondition,player1Piece,player2Piece,@columnController,@game)
	#aiFactory.createAI(player2AI,@game.winCondition,player2Piece,player1Piece,@columnController,@game)
	


#setup the window
  Gtk.init
    @builder = Gtk::Builder::new
    @builder.add_from_file("./lib/src/view/Multi_Game_Screen.glade")
	
    
	
# Step 1: get the window to terminate the program when it's destroyed
#
    window = @builder.get_object("window1")
    window.signal_connect( "destroy" ) 
{ 
	@client.quit(@gameName, @userName)
	Gtk.main_quit 
}

# Setup the Quit Button
	@builder.get_object("button1").signal_connect("clicked")
	{	
		window.destroy
	}

# Setup the Save Button
	@builder.get_object("button2").signal_connect("clicked"){
		@client.save(@gameName)	
	}


# Setup default Images for the board. So a Fresh Empty Game.
(1..42).each{|i| @builder.get_object("image"+i.to_s).set(@image_map[0])}

# Setup the Info Bar
	@builder.get_object("label1").text = "Let's Play"
# Setup the How to play
	@builder.get_object("label2").text = "How to Play: Connect pieces of your pattern\n" +
	"by row, column, or diagonally before your opponent does."

# Setup Clickable Images
(1..7).each{|i| @builder.get_object("eventbox" + i.to_s).signal_connect("button_press_event"){play_move(i)}}

@client._notifications

window.show()
    Gtk.main()
	end

def notify(*args)
	flags_map = {'CHANGE_TURN'=>0, 'WIN'=>1, 'STALEMATE'=>2, 'COLUMN_FULL'=>3, 'UNKNOWN_EXCEPTION'=>4 }

	if(flags_map[args[0]] == 0)

		board = args[1]
		message = args[2]
	
		update(board)
		
		# Play Continues	
		@builder.get_object("label1").text = message + " take your turn."
	
	elsif(flags_map[args[0]] == 1) 
		# Declare the Winner in the Info box up top
		board = args[1]
		message = args[2]

		update(board)

		@builder.get_object("label1").text = message + " wins!"
		@win = 1
	elsif(flags_map[args[0]] == 2)
		board = args[1]
		#Stalemate Tell the Info Box
		
		update(board)

		@builder.get_object("label1").text = "Stalemate!"
	elsif(flags_map[args[0]] == 3)
		#Column is full, Tell the player to pick another column
		@builder.get_object("label1").text = "Column Full. Try a different spot."
	else
		# Something has gone horribly wrong
		popup = Gtk::MessageDialog.new(self,:modal,:error,:close,"An unknown error has occured. Program exit.")
		popup.run
		popup.destroy	
	end
	
end

def play_move(col)
	if @win == 0
		@client.put(@gameName, col)
	else
		a=1
	end
end

def update(board)
#Update the Board View
	state_array = Array.new
	board.each{|row| row.each{|element| state_array << element}}
	(1..42).each{|i| @builder.get_object("image"+i.to_s).set(@image_map[state_array[i-1]])}
end

	
end
