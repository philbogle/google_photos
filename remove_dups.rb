#!/usr/bin/env ruby
#
# Reads the duplicates photos in the specified file and trashes all
# except the preferred version.
require_relative './drive'

def main
  if ARGV.length < 1
    puts "Usage: remove_dups.rb FILENAME.json [START_INDEX]"
    raise "Invalid argument"
  end
  filename = ARGV.shift

  if ARGV.length > 0
    start = ARGV.shift.to_i
  else
    start = 0
  end

  client = Drive.setup('remove_dups', '1.0.0')

  file = File.open(filename)
  map = JSON.parse(file.read)
  index = start
  puts "Start at #{start} out of #{map.size}"
  puts "Handling #{map.size - start} photos"
  for key, photos in map.to_a[start..(map.size)]
    preferred = photos.detect {|p| p['preferred'] == true}
    raise "No preferred photo found" unless preferred
    for photo in photos
      if photo != preferred
        index += 1
        id = photo['id']
        puts "#{index}. Trashing #{id}, keeping #{preferred['id']}"
        begin
          trash_file(client, id)
        rescue Exception => e
            puts "#{e}"
        end
      end
    end
  end
end

def trash_file(client, file_id)
  begin
    client.update_file(file_id, Google::Apis::DriveV3::File.new(trashed: true))
  rescue Google::Apis::Error => e
    puts "An error occurred: #{e.message}"
    nil
  end
end

main
