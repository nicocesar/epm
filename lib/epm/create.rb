#!/usr/bin/env ruby

module EPM
  class Create
    def initialize file, settings={}
      if file
        @uri      = URI.parse "http://localhost:#{settings['json-port']}"
        setup settings
        @contract = EPM::Compile.new(file, @settings).compile
      end
    end

    def deploy
      if @settings['preferred-client'] == 'cpp'
        params = {
          'sec' => @settings["address-private-key"],
          'xEndowment' => '',
          'bCode' => @contract,
          'xGas' => '100000',
          'xGasPrice' => ( @settings['gas-price'] || '100000000000000' )
        }
        post_body   = { 'method' => 'create', 'params' => params, 'id' => 'epm-rpc', "jsonrpc" => "2.0" }.to_json
      elsif @settings['preferred-client'] == ('go' || 'ethereal')
        params = {
          'body' => @contract,
          'value' => '',
          'gas' => '100000',
          'gasprice' => ( @settings['gas-price'] || '100000000000000' )
        }
        post_body   = { 'method' => 'EthereumApi.Create', 'params' => params, 'id' => 'epm-rpc', 'jsonrpc' => '2.0'}.to_json
      end
      return EPM::Server.http_post_request @uri, post_body
    end

    def setup settings
      unless settings.empty?
        @settings = settings
      else
        @settings = EPM::Settings.check
      end
    end
  end
end