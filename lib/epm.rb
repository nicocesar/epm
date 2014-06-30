#!/usr/bin/env ruby
# std_lib
require 'fileutils'
require 'tempfile'
require 'shellwords'
require 'json'
require 'net/http'
require 'uri'
require 'optparse'

# this gem
Dir[File.dirname(__FILE__) + '/epm/*.rb'].each {|file| require file }

module EPM
  extend self

  def compile args
    output = []
    until args.empty?
      file = args.shift
      settings = setup
      output << EPM::Compile.new(file, settings).compile
    end
    output
  end

  def create args
    output = []
    until args.empty?
      file = args.shift
      settings = setup
      output << EPM::Create.new(file, settings).deploy
    end
    output
  end

  def deploy args
    file     = args.shift
    settings = setup
    output   = EPM::Deploy.new(file, settings).deploy_package
  end

  def transact args
    recipient = args.shift
    data = args
    settings = setup
    EPM::Transact.new(recipient, data, settings).transact
  end

  def query args
    address = args.shift
    position = args.shift
    settings = setup
    EPM::Query.new(address, position, settings).query
  end

  def rpc args, opts
    name = args.shift
    arg_list = EPM::RPC.rpc_arg_list name
    opt_vals = {
      'a' => opts.a, 'x' => opts.x,'s' => opts.s, 'aDest' => opts.aDest,
      'bData' => opts.bData, 'sec' => opts.sec, 'xGas' => opts.xGas,
      'xGasPrice' => opts.xGasPrice, 'xValue' => opts.xValue,
      'bCode' => opts.bCode,'xEndowment' => opts.xEndowment
    }
    params = EPM::RPC.rpc_from_args name, arg_list, args, opt_vals
    return EPM::RPC.post_rpc_with_params name, params
  end

  def version
    return VERSION
  end

  def start opts
    EPM::Server.start opts.d
  end

  def stop
    EPM::Server.stop
  end

  def restart opts
    EPM::Server.stop
    EPM::Server.start opts.d
  end

  def setup
    return EPM::Settings.check
  end
end
