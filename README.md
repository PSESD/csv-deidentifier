# CSV Deidentification Scripts
Scripts for working with CSV student files, written in Ruby.

## `deidentify.rb`
Takes a CSV file and deidentifies it so that the data can be used for testing purposes without exposing student information. All ID's are regenerated with a random value but then temporarily stored in a mapping file so that multiple CSV files maintain the same mapping. This is important for deidentifying a group of files, such as a list of students and a separate list of student courses. After the deidentification process is complete, delete the `student_id_mapping.tmp` file and these records can no longer be tied to the individual student.

* ID's: randomized but mapped
* Names: randomly generated with Faker
* Gender: equally sampled from "M" or "F"
* Race/Ethnicity: equally sampled from the options hard-coded
* Birthdate and other dates: genericized to +/- 6 months of the actual value
* Phone Number: randomized to 206-555-####
* Incident ID: random number

For all other values in the row, the original value is left intact.

###Usage: 
```
./deidentify.rb path/to/infile.csv
```
or

```
./deidentify.rb infile.csv outfile.csv encoding force_special_date_format
```
Specify "auto" for any argument or leave it blank to skip it with the default value.


## `optionate.rb`

This script looks at each field and returns a json file of the possible values for each column in the CSV file. If there are too many unique values (such as names, or ID's, where basically every row is unique), a "TooManyValues" flag is returned instead. Use this method to collect the valid codeset options from live data.

###Usage: 
```
./optionate.rb path/to/infile.csv
```
or
```
./optionate.rb infile.csv outfile.json encoding
```
Specify "auto" for any argument or leave it blank to skip it with the default value.
