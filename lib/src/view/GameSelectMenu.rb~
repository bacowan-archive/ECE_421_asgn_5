require 'gtk2'
require_relative 'GameBoard.rb'

class GameMenu

  def initialize
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
	window.destroy
		
    }


    window.show()
    Gtk.main()
  end
	def start_game
		#Get Choices
		choices = (1..4).collect{|i| @builder.get_object("combobox" + i.to_s).active_text}
		new_game = GameBoard.new(choices)
			
	end 
	def resume
		@builder.get_object("window1").show
	end
end
