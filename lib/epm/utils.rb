#!/usr/bin/env ruby

module EPM
  module Server
    extend self

    def start debug=false
      settings = EPM::Settings.check
      if debug
        debug = ''
      else
        debug = '>> /dev/null'
      end

      unless is_eth_running?
        case settings['preferred-client']
        when 'cpp'
          server = "#{settings["path-to-eth"]} --json-rpc-port #{settings['json-port']} -r #{settings["remote"]} -d #{settings["directory"]} -m off -l #{settings["eth-listen-port"]} -c #{settings["name"]} -s #{settings["address-private-key"]} #{debug}"
        when 'go'
          server = "#{settings['path-to-go-ethereum']}"
        when 'ethereal'
          server = "#{settings['path-to-ethereal']}"
        end
        pid = spawn server
        sleep 7
      end
      return pid
    end

    def stop
      if is_eth_running?
        processes = eth_processes.map{|e| e.split(' ')[1]}
        processes.each{|p| `kill #{p}`}
      end
    end

    def is_eth_running?
      eth = eth_processes
      return (! eth.empty?)
    end

    def eth_processes
     a = `ps ux`.split("\n").select{|e| e[/eth.* --json-rpc-port/]}
     # a << `ps ux`.split("\n").select{|e| e[/ethereum/]}
     a << `ps ux`.split("\n").select{|e| e[/ethereal/]}
     a = a.flatten
     return a
    end

    def http_post_request uri, post_body
      unless is_eth_running?
        p "Ethereum RPC Server is not running. Starting now. Please be patient for it to load."
        start
      end
      http    = Net::HTTP.new uri.host, uri.port
      request = Net::HTTP::Post.new uri.request_uri
      request.content_type = 'application/json'
      request.body = post_body
      result = JSON.parse(http.request(request).body)['result']
      return result
    end
  end

  module Settings
    extend self

    def check
      install_setup_file unless have_setup_file
      return load_settings
    end

    def have_setup_file
      settings_file = File.join(ENV['HOME'], '.epm', 'epm-rpc.json')
      File.exists? settings_file
    end

    def install_setup_file
      settings_example = File.join(File.dirname(__FILE__), '..', '..', 'settings', 'epm-rpc.json')
      settings_file = File.join(ENV['HOME'], '.epm', 'epm-rpc.json')
      unless Dir.exists? File.dirname settings_file
        FileUtils.mkdir(File.dirname settings_file)
      end
      FileUtils.cp settings_example, settings_file
      settings = File.read settings_file
      print "Before we begin, I need to ask you two personal questions:\n"
      print "What is your primary account which I should be using to send transactions?\n\n"
      account = STDIN.gets.chomp
      print "Thanks. #{account} is what I will use.\n"
      print "Thanks. Now what is the private key for that account which I should be using?\n\n"
      secret = STDIN.gets.chomp
      print "Thanks. #{secret} is what I will use.\n"
      account = "0x#{account}" if account[0..1] != '0x'
      secret = "0x#{secret}" if secret[0..1] != '0x'
      settings.gsub!("0xact", account)
      settings.gsub!("0xsec", secret)
      File.open(settings_file, 'w'){|f| f.write(settings)}
    end

    def install_log_file
      log_file = File.join(ENV['HOME'], '.epm', 'deployed-log.csv')
      unless File.exists? log_file
        File.open(log_file, "w") {}
      end
      return log_file
    end

    def load_settings
      settings_file = File.join(ENV['HOME'], '.epm', 'epm-rpc.json')
      settings = JSON.parse(File.read(settings_file))
      log_file = install_log_file
      settings["log_file"] = log_file
      return settings
    end
  end

  module HexData
    extend self

    def hex_guard data
      if data[0..1] != "0x"
        data = "0x" + data
      end
      return data
    end

    def construct_data deconstructed_data
      data = "0x"
      deconstructed_data.each do |bits|
        if bits[0..1] == "0x"
          piece = bits[2..-1]
          piece = piece.rjust(64,'0')
        else
          piece = bits.unpack('c*').map{|s| s.to_s(16)}.join('')
          piece = piece.ljust(64,'0')
          if piece == "2727000000000000000000000000000000000000000000000000000000000000" || piece == "2222000000000000000000000000000000000000000000000000000000000000"
            piece = "0000000000000000000000000000000000000000000000000000000000000000"
          end
        end
        data << piece
      end
      return data
    end
  end

  module FileHelpers
    extend self

    def file_guard file
      contents = File.read file
      dir = File.dirname(File.absolute_path(file))
      unless dir == '/tmp'
        include_pattern = /(\(include \")(\..*)(\"\))/
        if contents[include_pattern]
          included = File.join(dir, $2)
          included = $1 + included + $3
          contents.gsub!(include_pattern, included)
        end
        save_temp_file contents, file
      else
        return file
      end
    end

    def save_temp_file contents, file
      tmp = Tempfile.new ['epm', File.extname(file)]
      File.open(tmp, 'w'){|f| f.write contents}
      return tmp.path
    end
  end
end
