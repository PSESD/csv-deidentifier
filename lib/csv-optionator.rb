require 'CSV'
require 'rubygems'
require 'URI'
require 'YAML'
require 'pp'
require 'JSON'

@headers = {}
@row_count = 0
@student_ids = []

class TooManyValues
  def initialize(number, row_count)
    @count = number
    @row_count = row_count
  end
end

# Open the requested CSV file and pull out all of the headers and values into an array.
def process_csv(file_path)
  options = { :headers => true }
  options[:encoding] = @encoding if @encoding
  begin
    CSV.foreach(file_path, options) do |row|
      attrs = row.to_hash
      for key, value in attrs
        @headers[key] ||= []
        @headers[key] << value
      end
      student_id = attrs["StudentID"] || attrs["Student ID"]
      unless @student_ids.include?(student_id)
        @row_count += 1
        @student_ids << student_id
      end
      print("Processing row " + @row_count.to_s + "\r") && $stdout.flush      
    end
  rescue ArgumentError => e
    raise Exception.new "There seems to be an encoding problem ('#{e}'). Please try again and specify the encoding for the file. Try one of these: #{Encoding.list.collect(&:to_s)}"
  end
end

# Return only the unique values of @headers.
def unique_values
  unique_hash = Hash[@headers.dup.map{|k,v| [k,v.uniq] }]
  for header, values in unique_hash
    unique_hash[header] = TooManyValues.new(values.count, @row_count) if too_many_values(values)
  end
end

# Decide if there are too many unique values if more than 65% are unique.
def too_many_values(array)
  threshold = 0.05 # change the threshold for how many unique values are allowed
  return true if array.size > (@row_count * threshold)
end
