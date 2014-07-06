#!/usr/bin/env ruby

module EPM
  class Transact
    def initialize recipient, data, settings={}
      @uri       = URI.parse "http://localhost:#{settings['json-port']}"
      setup settings
      @recipient = EPM::HexData.hex_guard recipient
      @data      = EPM::HexData.construct_data data
    end

    def transact value=''
      if @settings['preferred-client'] == 'cpp'
        params = {
          'sec' => @settings["address-private-key"],
          'xValue' => value,
          'aDest' => @recipient,
          'bData' => @data,
          'xGas' => '100000',
          'xGasPrice' => ( @settings['gas-price'] || '100000000000000' )
        }
        post_body = { 'method' => 'transact', 'params' => params, 'id' => 'epm-rpc', "jsonrpc" => "2.0" }.to_json
      elsif @settings['preferred-client'] == ('go' || 'ethereal')
        params = {
          'recipient' => @recipient,
          'value' => value,
          'gas' => '100000',
          'gasprice' => ( @settings['gas-price'] || '100000000000000' ),
          'body' => @data,
        }
        post_body = { 'method' => 'EthereumApi.Transact', 'params' => params, 'id' => 'epm-rpc', "jsonrpc" => "2.0" }.to_json
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