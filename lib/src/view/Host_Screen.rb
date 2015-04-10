require 'gtk2'

class HostScreen

def initialize(parentBoard)
 @parent = parentBoard
 Gtk.init
 @builder = Gtk::Builder::new
 @builder.add_from_file("./lib/src/view/Host_Screen.glade")

window = @builder.get_object("window1")
window.signal_connect( "destroy" ) { Gtk.main_quit }
 
 @builder.get_object("button1").signal_connect("clicked"){
	gameName = @builder.get_object("entry1")
	userName = @builder.get_object("entry2")
	setParentNames(gameName.text,userName.text)
	window.destroy
}
 @builder.get_object("button2").signal_connect("clicked"){window.destroy}

window.show()
    Gtk.main()

end

def setParentNames(gameName, userName)
 @parent.setNames(gameName, userName)
end

end
