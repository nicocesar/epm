#!/usr/bin/env ruby

class Deploy
  def initialize def_file, settings={}
    @dirname  = File.dirname(File.absolute_path(def_file))
    @log_file = File.join(ENV['HOME'], '.epm', 'deployed-log.csv')
    @settings = settings
    @brain    = {}
    parse_definition_file def_file
  end

  def parse_definition_file def_file
    if def_file
      commands = File.readlines def_file
      commands = commands.reject{|cmd| cmd[/\A#/] || cmd[/\A$/]}.map{|cmd| cmd.gsub("\n",'')}
      commands = commands.inject([]) do |arr,ele|
        ele[/\A\S+/] ? arr << [ele] : arr[-1] << ele.strip.split(' => ')
        arr
      end
      commands.each do |cmd|
        dowit = cmd.shift
        case dowit
        when 'deploy:'
          deploy cmd.shift
          sleep 1
        when 'modify-deploy:'
          modify_deploy cmd
          sleep 1
        when 'transact:'
          transact cmd.shift
          sleep 1
        when 'query:'
          query cmd.shift
        when 'log:'
          log cmd.shift
        when 'set:'
          set_var cmd.shift
        end
      end
    end
  end

  def deploy command
    deploy_k = command.shift
    k_name = command.shift
    p "Deploying #{deploy_k} with name of #{k_name.gsub(/(\{|\})/,'')}."
    k_address = Create.new File.join(@dirname, deploy_k), @settings
    @brain[k_name] = k_address
    p "#{k_name} => #{k_address}"
  end

  def modify_deploy command
    deploy_k = command[0].shift
    k_name = command[0].shift
    dump = command.shift
    until command.empty?
      cmd = command.shift
      to_replace = cmd.shift
      replacer = cmd.shift
      until ! replacer[/(\{\{.*?\}\})/]
        replacer.gsub!($1, @brain[$1])
      end
      tmp = Tempfile.new ['epm', File.extname(deploy_k)]
      k_value = File.read (@dirname + "/" + deploy_k)
      k_value = k_value.gsub "#{to_replace}", "#{replacer}"
      File.open(tmp, 'w'){|f| f.write k_value}
    end
    p "After modifying, am deploying #{deploy_k} with name of #{k_name.gsub(/(\{|\})/,'')}."
    k_address = Create.new tmp.path, @settings
    @brain[k_name] = k_address
    p "#{k_name} => #{k_address}"
  end

  def transact command
    recipient = command.shift
    until ! recipient[/(\{\{.*?\}\})/]
      recipient.gsub!($1, @brain[$1])
    end
    data = command.shift
    until ! data[/(\{\{.*?\}\})/]
      data.gsub!($1,@brain[$1])
    end
    p "Sending #{recipient} the data: #{data}."
    Transact.new recipient, data, @settings
  end

  def query command
    contract = command.shift
    address = command.shift
    name = command.shift
    until ! contract[/(\{\{.*?\}\})/]
      contract.gsub!($1,@brain[$1])
    end
    until ! address[/(\{\{.*?\}\})/]
      address.gsub!($1,@brain[$1])
    end
    p "Querying #{contract} at: #{address}."
    storage = Query.new contract, address, @settings
    p "#{contract}:#{address} => #{storage}"
    @brain[name] = storage
  end

  def log command
    address = command.shift
    name = command.shift
    until ! address[/(\{\{.*?\}\})/]
      address.gsub!($1,@brain[$1])
    end
    until ! name[/(\{\{.*?\}\})/]
      name.gsub!($1,@brain[$1])
    end
    log_entry = [address, name].join(',')
    p "Logging [#{address},#{name}]"
    `echo #{log_entry} >> #{@log_file}`
  end

  def set_var command
    key = command.shift
    value = command.shift
    p "Setting #{key} to #{value}"
    @brain[key] = value
  end
end