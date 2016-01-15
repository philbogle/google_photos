#!/usr/bin/env ruby

# Utility to output the metadata for all of the user's Google Photos to a specified file.
# Usage: ./print_photos_json.rb photos.json_list
#
# Each line is a JSON-encoded hash of metadata about the photos.
#
# {"id":"11kkcMe21Td8pa5qXkPQERJuvhi9IRKGPdQ","thumbnailLink":"https://lh4.googleusercontent.com/Q9v52O5R5PVKtPywfx6j9v5rl2m04wyS0dM9eQ3qyZ2bvhvIPlNwT5VFw6YTp4esRW7sRNVdfEFx=s220","title":"IMG_20160101_191240.jpg","mimeType":"image/jpeg","description":"","labels":{"starred":false,"hidden":false,"trashed":false,"restricted":false,"viewed":false},"createdDate":"2016-01-02T03:12:42.000Z","version":"453629","downloadUrl":"https://doc-14-84-docs.googleusercontent.com/docs/securesc/irr3ri85at7sfuel5jjiu7ectbgaunak/mfenj2t9cu8efqbm272m1c03d14oagq0/1451764800000/02062841437398388950/02062841437398388950/11kkcMe21Td8pa5qXkPQERJuvhi9IRKGPdQ?e=download&gd=true","originalFilename":"IMG_20160101_191240.jpg","fileExtension":"jpg","md5Checksum":"ba25e776b3f4e66fe0c97765ae405251","fileSize":"3645041","quotaBytesUsed":"0","imageMediaMetadata":{"width":4000,"height":2992,"date":"2016:01:01 19:12:42","cameraModel":"Nexus 6P"},"index":0}

require_relative './drive'
require 'json'

def print_photos_json(client, file)
  yield_all_photos(client) do |photo|
    file.write(photo.to_h.to_json)
    file.write("\n")
  end
end

def yield_all_photos(client, &block)
  fields = %q(next_page_token,files(name, id, size, image_media_metadata, thumbnail_link, created_time, modified_time, version, md5_checksum, original_filename))
  page_token = nil
  index = 0
  begin
    result = client.list_files(q: 'trashed=false',
                               spaces: 'photos',
                               fields: fields,
                               page_size: 1000,
                               page_token: page_token)
    result.files.each do |photo|
      block.call(photo, index)
      index += 1
    end
    STDERR.puts "Fetched #{result.files.length} items, total #{index}."
    page_token = result.next_page_token
  end while page_token != nil
end

if __FILE__ == $0
  if ARGV.length != 1
     STDERR.puts "Usage: ./print_photos_json.rb FILENAME.json_list"
    exit 1
  end

  filename = ARGV.shift
  f = File.open(filename, 'w')

  client = Drive.setup('print_photos_json', '1.0.0')
  print_photos_json(client, f)
end
