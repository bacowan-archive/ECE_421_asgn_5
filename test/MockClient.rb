require 'xmlrpc/client'
require_relative '../src/GameServer'

server = XMLRPC::Client.new(ENV['HOSTNAME'], '/RPC2', GameServer.DEFAULT_PORT)

