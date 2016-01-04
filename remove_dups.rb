#!/usr/bin/env ruby
#
# Reads the duplicates photos in the specified file and trashes all
# except the preferred version.
require_relative './drive'

def main
  if ARGV.length != 1
    puts "Usage: remove_dups.rb FILENAME.json"
    raise "Invalid argument"
  end
  filename = ARGV.shift

  client, drive = Drive.setup('remove_dups', '1.0.0')

  file = File.open(filename)
  puts file
  map = JSON.parse(file.read)
  puts map.size
  start = 0
  count = start
  puts "Handling #{map.size} photos"
  for key, photos in map.to_a[start..(map.size)]
    preferred = photos.detect {|p| p['preferred'] == true}
    raise "No preferred photo found" unless preferred
    for photo in photos
      if photo != preferred
        count += 1
        id = photo['id']
        puts "#{count}. Trashing #{id}, keeping #{preferred['id']}"
        trash_file(client, id)
      end
    end
  end
end

def trash_file(client, file_id)
  drive = client.discovered_api('drive', 'v2')
  result = client.execute(
    :api_method => drive.files.trash,
    :parameters => { 'fileId' => file_id })
  if result.status == 200
    return result.data
  else
    puts "An error occurred: #{result.data['error']['message']}"
  end
end

main
