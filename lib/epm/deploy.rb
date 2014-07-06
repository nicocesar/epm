#!/usr/bin/env ruby

module EPM
  class Deploy
    def initialize def_file, settings={}
      @dirname  = File.dirname(File.absolute_path(def_file))
      @log_file = File.join(ENV['HOME'], '.epm', 'deployed-log.csv')
      setup settings
      @brain    = {}
      @def_file = def_file
    end

    def deploy_package
      get_remote_if_remote
      if @def_file
        p "Deploying: #{@def_file}."
        commands = File.readlines @def_file
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
          when 'endow:'
            endow cmd.shift
            sleep 1
          end
        end
      end
    end

    def deploy command
      deploy_k = command.shift
      k_name = command.shift
      p "Deploying #{deploy_k} with name of #{k_name.gsub(/(\{|\})/,'')}."
      k_address = EPM::Create.new(File.join(@dirname, deploy_k), @settings).deploy
      @brain[k_name] = k_address
      p "#{k_name} => #{k_address}"
    end

    def modify_deploy command
      deploy_k = command[0].shift
      deploy_k = EPM::FileHelpers.file_guard(File.join(@dirname, deploy_k))
      k_name = command[0].shift
      dump = command.shift
      until command.empty?
        cmd = command.shift
        to_replace = cmd.shift
        replacer = cmd.shift
        until ! replacer[/(\{\{.*?\}\})/]
          replacer.gsub!($1, @brain[$1])
        end
        k_value = File.read deploy_k
        k_value = k_value.gsub "#{to_replace}", "#{replacer}"
        File.open(deploy_k, 'w'){|f| f.write k_value}
      end
      p "After modifying, am deploying #{deploy_k} with name of #{k_name.gsub(/(\{|\})/,'')}."
      k_address = EPM::Create.new(deploy_k, @settings).deploy
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
      data = data.split(' ')
      p "Sending #{recipient} the data: #{data}."
      EPM::Transact.new(recipient, data, @settings).transact
    end

    def endow command
      recipient = command.shift
      until ! recipient[/(\{\{.*?\}\})/]
        recipient.gsub!($1, @brain[$1])
      end
      endowment = command.shift
      p "Sending #{recipient} an endowment of: #{endowment}."
      EPM::Transact.new(recipient, '', @settings).transact endowment
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
      storage = EPM::Query.new(contract, address, @settings).query
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

    def get_remote_if_remote
      if is_it_a_remote_file?
        begin
          p "Cloning into Remote."
          tmp = Tempfile.new 'epm'
          Dir.chdir File.dirname tmp.path
          unless File.directory? 'cloned'
            Dir.mkdir 'cloned'
          end
          Dir.chdir 'cloned'
          begin
            `git clone #{@def_file}`
          end
          dir = Dir.glob('*')[0]
          dir = File.dirname(tmp.path) + '/cloned/' + dir
          Dir.chdir dir
          def_files = Dir.glob('*').select {|f| File.extname(f) == '.package-definition'}
          if def_files.empty?
            dirs = Dir.glob('*').select {|f| File.directory? f}
            dirs.each do |d|
              Dir.chdir d
              def_files << Dir.glob('*').inject([]) do |arr,f|
                if File.extname(f) == '.package-definition'
                  arr << d + '/' + f
                end
                arr
              end
              Dir.chdir dir
            end
          end
          def_files.flatten!
          def_files.each do |df|
            this_def_dir = File.dirname df
            this_def_file = File.basename df
            Dir.chdir this_def_dir
            EPM::Deploy.new(this_def_file, @settings).deploy_package
            Dir.chdir dir
          end
        rescue Exception => e
          p "There was an error during that deploy."
          puts e.message
        ensure
          remote_cleanup tmp
          tmp.unlink
          @def_file = false
        end
      end
    end

    def is_it_a_remote_file?
      @remote = false
      if @def_file[/https*:\/\//] || @def_file[/gits*:\/\//] || @def_file[/.+@.+\..+:/]
        @remote = true
        return true
      end
      false
    end

    def remote_cleanup tmp
      if @remote
        Dir.chdir File.dirname tmp.path
        FileUtils.rm_rf 'cloned'
      end
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