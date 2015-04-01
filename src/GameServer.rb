require 'xmlrpc/server'

DEFAULT_PORT = 50539

module GameServer
  def start(*args)
    if args.length == 0
      port = DEFAULT_PORT
    elsif args.length == 1
      port = args[0]
    else
      raise 'wrong number of arguments'
    end
    server = XMLRPC::Server.new(port)
    server.add_handler(GameServerCls::INTERFACE, GameServerCls.new)
    server.serve
  end
end