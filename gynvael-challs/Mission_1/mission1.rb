#!/usr/bin/env ruby

require 'digest'

$stdout.sync = true # print progress dots nicely

target = '76fb930fd0dbc6cba6cf5bd85005a92a'
target_bytes = [target].pack('H*').split('')
lookup = {}
i = 0

File.foreach('words_alpha.txt') do |line|
	i += 1
	print '.' if (i % 1000 == 0)
	line.strip!
	if (line.length == 8)
		line_hash = Digest::MD5.digest line # byte output!
		if lookup.key? line_hash
			puts "\n[!] Found it: #{lookup[line_hash]} and #{line}"
			break
		else
			xor = target_bytes.zip(line_hash.split('')).map { |a, b| (a.ord ^ b.ord).chr }.join('')
			lookup[xor] = line
		end
	end
end
