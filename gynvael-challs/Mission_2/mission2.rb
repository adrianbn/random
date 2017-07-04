#!/usr/bin/env ruby

huff_tree = 
	[
		[
			[
				[
					[
						['5'], 
						[
							[
								['6'], 
								['7']
								], 
							[
								['8'], 
								['9']
								]
							]
						], 
					['A']
					], 
				['2']
				], 
			[
				['1'], 
				[
					['3'], 
					[
						['B'], 
						['C']
						]
					]
				]
			], 
		['0']
		], 
	['4', 
		[
			[
				['F'], 
				['E']
				], 
			['D']
			]
		]

encoded_msg = File.read('huffman_encoded.txt')
encoded_msg.strip!.gsub!(/\r?\n?/, '') # remove trailing spaces, and new lines and line breaks.
encoded_msg = encoded_msg.split('').map(&:to_i)
res = []
path = huff_tree

encoded_msg.each do |bit|
	path = path.dig(bit)
	raise StandardError, "Can't decode text with the given tree!" if path.nil?
	if path.length == 1
		res.push(path)
		path = huff_tree
	end
end

puts res.join('').scan(/.{2}/).map{ |n| n.to_i(16).chr }.join('')