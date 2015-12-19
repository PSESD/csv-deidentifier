require 'CSV'
require 'rubygems'
require 'URI'
require 'pp'
require 'JSON'
require 'faker'
require 'YAML'
$VERBOSE = nil # suppress some errors

MAPPING_FILE = "./student_id_mapping.tmp"
@student_ids = {}
@try_special_format = false

# Load the existing values from temp file if needed, and return the entire set of student ID mappings.
# This mapping allows you to run this script on multiple related files and keep related records linked.
# For example, a file with student demographics and student classes need to stay linked together with
# the same student ID, but we want that ID to be random and not tied to that student. Once you're done
# with a set of files, delete the +MAPPING_FILE+ and the ID's will no longer be linkable to the actual
# students.
def student_id_mapping
  if @student_ids.empty? && File.exist?(MAPPING_FILE)
    puts "Loading existing ID mappings from #{MAPPING_FILE}"
    @student_ids = YAML.load_file(MAPPING_FILE)
  end
  @student_ids
end

# Return a unique deidentified ID for the specified ID. If it already exists in the mapping, return
# that value. Otherwise, construct a random number that matches the length of the original ID, and
# ensure that it's unique compared to all other randomly generated ID's in the mapping table.
def deidentified_id(old_id)
  old_id = old_id.to_s
  return @student_ids[old_id] if student_id_mapping[old_id]
  @student_ids[old_id] = rand.to_s[2..old_id.to_s.length+1] while !student_id_mapping.values.include?(@student_ids[old_id])
  @student_ids[old_id]
end

# Return a random date within the range of 6 months before or after the given date. Useful for deidentifying
# dates but still keeping them close enough to be relevant for the record, like maintaining a person's
# approximate age or staying within the same school year of the existing event.
# 
# This method expects that, by default, the date will be automatically be parseable with +Date.parse+. If
# that raises an error, the method will try again with the standard "American" date format of MM/DD/YYYY.
# If that works, then we'll use that format for the rest of the script's life (since we assume that all other
# dates are the same format. You can manually change this by setting +@try_special_format+ to true.
def genericized_date(old_date, date_format = '%m/%d/%Y')
  return nil unless old_date
  dt = @try_special_format ? Date.strptime(old_date, date_format) : Date.parse(old_date)
  offset = 6*30 # days
  new_date = Faker::Date.between(dt - offset, dt + offset)
  @try_special_format ? new_date.strftime(date_format) : new_date
rescue ArgumentError => e
  if e.message == "invalid date" && !@try_special_format
    @try_special_format = true
    retry
  else
    raise
  end
end

# After everything is done, save the mapping file out to the temp file path for future use with other files.
def save_student_id_mapping
  open(MAPPING_FILE, 'w') { |f| f.write @student_ids.to_yaml }
  puts "Saved ID mappings to #{MAPPING_FILE}"
end

# The primary method of this library. Opens up the input CSV file, deidentifies each row, and writes it
# out to the new output file, ovewriting the entire file.
def deidentify(infile, outfile)
  @row_count = 0
  CSV.open(outfile, 'w') do |output|
    load_csv(infile).each do |csv_array|
      new_attrs = csv_array.to_hash
      output << new_attrs.keys if @row_count.zero?
      new_attrs = deidentify_hash(new_attrs)
      output << new_attrs.values
      @row_count += 1
      print("Processing row " + @row_count.to_s + "\r") && $stdout.flush
    end
  end
  save_student_id_mapping
  puts "Wrote out #{@row_count} rows to #{outfile}"
end

# Load the input CSV file, using the specified encoding if needed. Raise an error if the file can't
# be opened and parsed.
def load_csv(infile)
  options = { :headers => true }
  options[:encoding] = @encoding if @encoding
  begin    
    CSV.read(infile, options)
  rescue ArgumentError => e
    raise Exception.new "There seems to be an encoding problem ('#{e}'). Please try again and 
      specify the encoding for the file. Try one of these: #{Encoding.list.collect(&:to_s)}"
  end
end

# Given a hash representing a row in the CSV file, deidentify the sensitive data columns.
# 
# * ID's: randomized but mapped
# * Names: randomly generated with Faker
# * Gender: equally sampled from "M" or "F"
# * Race/Ethnicity: equally sampled from the options hard-coded
# * Birthdate: genericized to +/- 6 months of the actual value
# * Phone Number: randomized to 206-555-####
# * Incident ID: random number
# 
# For all other values in the hash, the original value is left intact.
def deidentify_hash(old_hash)
  result = old_hash.dup
  for key, value in old_hash
    result[key] = case key
    when "StudentID", "Student ID", "State Student ID", "School ID"
      deidentified_id(value)
    when "FirstName", "Student First Name", "Student Middle Name"
      value.to_s.upcase.eql?(value) ? Faker::Name.first_name.upcase : Faker::Name.first_name
    when "LastName", "Student Last Name"
      value.to_s.upcase.eql?(value) ? Faker::Name.last_name.upcase : Faker::Name.last_name
    when "Gender"
      %w(M F).sample
    when "RaceEthnicity" # Seattle
      ["Hispanic", "African American or Black", "Caucasian", "Multiracial", "Asian", "Pacific Islander", "American Indian"].sample
    when "Ethnicity/Race" # Renton
      ["Asian", "Hispanic/Latino of any race(s)", "Black / African American", "White", "Two or More Races", "Native Hawaiian / Pac Islander", "American Indian/Alaska Native"].sample
    when "Birth Date", "Discipline Incident Date"
      genericized_date(value)
    when "PhoneNumber"
      Faker::Base.numerify('206-555-####')
    when "IncidentID", "Unique Discipline ID"
      Faker::Base.numerify('#####')
    when "TeacherNames" # Seattle
      "#{Faker::Name.last_name}, #{Faker::Name.first_name}"
    when "Teacher" # Renton
      value.to_s.upcase.eql?(value) ? Faker::Name.last_name.upcase : Faker::Name.last_name
    when "Time To Serve"
      value.nil? ? nil : (0..85).step(0.5).to_a.sample
    else
      value
    end
  end
  result
end