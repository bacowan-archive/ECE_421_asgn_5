require 'gtk2'

class HostScreen

def initialize(parentBoard)
 @parent = parentBoard
 Gtk.init
 @builder = Gtk::Builder::new
 @builder.add_from_file("./lib/src/view/Host_Screen.glade")
 
 @builder.get_object("button1").signal_connect("clicked")
{
	setParentNames(@builder.get_object("entry1").text,@builder.get_object("entry2").text)
	window.destroy
}
 @builder.get_object("button2").signal_connect("clicked"){window.destroy}

end

def setParentNames(gameName, userName)
 @parent.setNames(gameName, userName)
end

