# joins an arbitrary number of csv files together on a shared column
#   csv files should have a header row
#   assumes only one row for each join_value per file
#   discards join values unless they have a row in every file

# usage
#   ruby "key" file1 file2 ...

require "csv"
require "set"

$key = ARGV[0]
$files = ARGV[1..-1]


$accumulator = {}

$headers = [$key]

$files.each do |file|
  fh = File.open(file, "r")

  # read the header and detect the key index
  fields = CSV.parse_line(fh.gets.strip)
  key_index = fields.index($key)
  raise "Could not detect column for key #{key} in file #{file}" unless key_index

  fields.delete_at(key_index)
  $headers += fields
  until fh.eof?
    line = fh.gets
    values = CSV.parse_line(line.strip)
    join_value = values[key_index]
    values.delete_at(key_index)
    $accumulator[file] ||= {}
    $accumulator[file][join_value] = values
  end

  fh.close
end

# record all join_values
$join_values = nil
$files.each do |file|
  join_values = $accumulator[file].keys
  if $join_values.nil?
    $join_values = Set.new(join_values)
  else
    $join_values = $join_values & Set.new(join_values)
  end
end

# output as csv
puts $headers.to_csv
$join_values.each do |join_value|
  row = [join_value]
  $files.each do |file|
    row += $accumulator[file][join_value]
  end
  puts row.to_csv
end

