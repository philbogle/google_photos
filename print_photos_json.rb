#!/usr/bin/env ruby

# Utility to output a STDOUT the metadta for all of the user's Google Photos.
#
# Each line is a JSON-encoded hash of metadata about the photos.
#
# {"id":"11kkcMe21Td8pa5qXkPQERJuvhi9IRKGPdQ","thumbnailLink":"https://lh4.googleusercontent.com/Q9v52O5R5PVKtPywfx6j9v5rl2m04wyS0dM9eQ3qyZ2bvhvIPlNwT5VFw6YTp4esRW7sRNVdfEFx=s220","title":"IMG_20160101_191240.jpg","mimeType":"image/jpeg","description":"","labels":{"starred":false,"hidden":false,"trashed":false,"restricted":false,"viewed":false},"createdDate":"2016-01-02T03:12:42.000Z","version":"453629","downloadUrl":"https://doc-14-84-docs.googleusercontent.com/docs/securesc/irr3ri85at7sfuel5jjiu7ectbgaunak/mfenj2t9cu8efqbm272m1c03d14oagq0/1451764800000/02062841437398388950/02062841437398388950/11kkcMe21Td8pa5qXkPQERJuvhi9IRKGPdQ?e=download&gd=true","originalFilename":"IMG_20160101_191240.jpg","fileExtension":"jpg","md5Checksum":"ba25e776b3f4e66fe0c97765ae405251","fileSize":"3645041","quotaBytesUsed":"0","imageMediaMetadata":{"width":4000,"height":2992,"date":"2016:01:01 19:12:42","cameraModel":"Nexus 6P"},"index":0}

require_relative './drive'

def print_photos_json(client)
  yield_all_photos(client) do |photo|
    puts photo.to_json
  end
end

def yield_all_photos(client, &block)
  drive = client.discovered_api('drive', 'v2')
  page_token = nil
  index = 0
  while true
    succeeded = false
    while not succeeded
      parameters = {
        'spaces' => 'photos',
        'maxResults' => 500,
        # Uncomment and edit the following line if you want to restrict the fields dumped.
        # 'fields' => 'items(title,imageMediaMetadata(date,width,height,rotation,cameraModel),fileSize,id,thumbnailLink,downloadUrl,createdDate,modifiedDate,version,description,labels,originalFilename,md5Checksum,quotaBytesUsed,alternateLink),kind,nextPageToken'
      }
      parameters['pageToken'] = page_token if page_token.to_s != ''
      result = client.execute(:api_method => drive.files.list, :parameters => parameters)
      status = result.status
      if status == 200  # Success
        succeeded = true
        photos = result.data
        photos.items.each do |photo|
          photo['index'] = index
          index += 1
          next if photo['labels'] && (photo['labels']['trashed'] || photo['labels']['hidden'])
          block.call(photo)
        end
        STDERR.puts "Fetched #{photos.items.length} items, total #{index}."
        page_token = photos.next_page_token
      elsif status >= 500 && status <= 599  # Transient failure
        STDERR.puts "An transient error occurred, retrying #{result.data['error']['message']}"
      else  # Permanent failure
        raise "A permanent error occurred giving up:  #{result.data['error']['message']}"
      end
    end # while not succeeded

    break if page_token.to_s == ''
  end
end

if __FILE__ == $0
  client, drive = Drive.setup('print_photos_json', '1.0.0')
  print_photos_json(client)
end
