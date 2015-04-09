require_relative 'CommandLineInterface'
module CommandLineGame
  def start
    interface = CommandLineInterface.new
    interface.start
  end
end