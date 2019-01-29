require 'json'

dir = ARGV.shift.dup
dir.gsub!(/\/+$/, '')
Dir["#{dir}/media/*.*"].each do |file|
  sleep 300
  next if file =~ /.json/
  next if File.exists? "#{file}.json"
  id=`python3 /usr/local/bin/youtube-upload --privacy unlisted --title "#{file}" "#{file}"`
  STDERR.puts "Uploaded #{id} saving to: #{file}.json"
  File.open("#{file}.json", "w") do |f|
    f.write id.to_json
  end
end
