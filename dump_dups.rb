# Command line utlity for dumping potentially duplicate photos based on various heuristics.
#
# dups: photos which have the same name and taken date.
# rotate: photos which are dups and with dimensions h*w and w*h.

require 'json'
require 'pp'

def main()
  if ARGV.length != 2
    puts "Usage: ./analyze_dups FILENAME (rotation|dups)"
    raise "Invalid usage"
  end

  filename = ARGV.shift
  action = ARGV.shift

  photo_map = {}
  for line in File.open(filename)
    photo = JSON.parse(line)

    # Skip trashed and hidden photos
    next if photo['labels'] && (photo['labels']['trashed'] || photo['labels']['hidden'])

    key = photo_key(photo)
    next if !key
    (photo_map[key] ||= []) << photo
  end

  duplicated_photos_map =
    case action
    when 'rotate'
      photo_map.select {|key, photos| is_rotation(photos)}
    when 'dups'
      photo_map.select {|key, photos| photos.length > 1}
    else
      raise "Unexpected action #{action}"
    end

  duplicated_photos_map.each do |key, photos|
    photos.each do |photo|
      id = photo['id']
      # Fix thumbnail link to a permanently valid link.  (The URL generated in the API is only valid for a short time.)
      photo['thumbnailLink'] = "https://drive.google.com/thumbnail?authuser=0&sz=w320&id=#{id}"

      # Delete unininteresting keys
      %w(downloadUrl parents userPermission lastModifyingUser labels selfLink etag owners owenerNamesspaces headRevisionId).each do |key|
        photo.delete(key)
      end
    end
  end

  jj duplicated_photos_map
end

def photo_key(photo)
  metadata = photo['imageMediaMetadata']
  filename = photo['originalFilename']
  return nil unless filename && metadata && metadata['date'] && metadata['date'] != '0000:00:00 00:00:00'
  "#{metadata['date']}:#{filename}"
end

def is_rotation(photos)
  return false unless photos.length == 2
  p1, p2 = photos
  return p1['imageMediaMetadata']['width'] == p2['imageMediaMetadata']['height'] &&
    p2['imageMediaMetadata']['width'] == p2['imageMediaMetadata']['width']
end

main
