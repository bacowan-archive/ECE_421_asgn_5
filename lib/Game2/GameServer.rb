require 'xmlrpc/server'
require_relative 'GameServerCls'

module GameServer

  def GameServer.DEFAULT_PORT
    50539
  end

  def start(*args)
    if args.length == 0
      port = GameServer.DEFAULT_PORT
    elsif args.length == 1
      port = args[0]
    else
      raise 'wrong number of arguments'
    end
    server = XMLRPC::Server.new(port, ENV['HOSTNAME'])
    server.add_handler(GameServerCls::INTERFACE, GameServerCls.new, 10)
    server.serve
  end
end
