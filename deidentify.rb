#!/usr/bin/env ruby
require './lib/csv-deidentifier.rb'

directory = '.'
infile = ARGV[0].to_s
outfile = (ARGV[1] == "auto" || ARGV[1].nil?) ? infile.gsub(".csv", "-deidentified.csv").to_s : ARGV[1].to_s
@encoding = ARGV[2] == "auto" ? nil : ARGV[2]
raise Exception.new("Usage: ./deidentify.rb infile.csv outfile.csv encoding") if infile == '' || outfile == ''

@try_special_format = ARGV[3].eql?("true") # for dates
puts "Forcing special date formats when translating." if @try_special_format

puts "Deidentifying #{infile} => #{outfile}"
deidentify(infile, outfile)