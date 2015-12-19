#!/usr/bin/env ruby
require './lib/csv-optionator.rb'

directory = '.'
infile = ARGV[0].to_s
outfile = (ARGV[1] == "auto" || ARGV[1].nil?) ? infile.gsub(".csv", "-options.json").to_s : ARGV[1].to_s
@encoding = ARGV[2]
raise Exception.new("Usage: ./optionate.rb infile.csv outfile.json encoding") if infile == '' || outfile == ''

puts "Generating option sets for #{infile} => #{outfile}"
process_csv(infile)
pp unique_values
open(outfile, 'w') { |f|
  f.puts unique_values.to_json(      
    :allow_nan             => false,
    :array_nl              => "\n",
    :ascii_only            => false,
    :buffer_initial_length => 1024,
    :quirks_mode           => false,
    :depth                 => 0,
    :indent                => "  ",
    :max_nesting           => 100,
    :object_nl             => "\n",
    :space                 => " ",
    :space_before          => ""
  )
}
puts "Wrote out #{@row_count} rows to #{outfile}"
