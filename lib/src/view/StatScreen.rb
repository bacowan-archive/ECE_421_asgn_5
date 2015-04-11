require 'gtk2'

class StatScreen

def initialize(client)

  @client = client
  Gtk.init
  @builder = Gtk::Builder::new
  @builder.add_from_file("./lib/src/view/Stat_Screen.glade")

  window = @builder.get_object("window1")
  window.signal_connect( "destroy" ){ 
	Gtk.main_quit 
  }
  @builder.get_object("button1").signal_connect("clicked"){	
		window.destroy
  }

  my_stats = '' #"username wins lost ties\n"

  stats = @client.getStats()
  stats.each{|item| my_stats = my_stats + item[0] + " has " + item[1].to_s + " wins, " + item[2].to_s + " losses, and " + item[3].to_s + " ties.\n"}

  textView = @builder.get_object("textview1")
  buffer = textView.buffer
  buffer.text = my_stats
  textView.buffer = buffer


  window.show()
  Gtk.main()
end


end
