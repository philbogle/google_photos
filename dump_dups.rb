# Command line utlity for dumping potentially duplicate photos based on various heuristics.
#
# dups: photos which have the same name and taken date.
# rotate: photos which are dups and with dimensions h*w and w*h.

require 'json'
require 'pp'

def main()
  if ARGV.length != 2
    puts "Usage: ./dump_dups FILENAME (rotation|resize|dups)"
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
    when 'dups'
      photo_map.select {|key, photos| photos.length > 1}
    when 'resize'
      photo_map.select {|key, photos| is_resizing(photos)}
    else
      raise "Unexpected action #{action}"
    end

  duplicated_photos_map.each do |key, photos|
    preferred_photo = nil
    photos.each do |photo|
      id = photo['id']
      # Fix thumbnail link to a permanently valid link.  (The URL generated in the API is only valid for a short time.)
      photo['thumbnailLink'] = "https://drive.google.com/thumbnail?authuser=0&sz=w320&id=#{id}"

      if action == 'resize' && (!preferred_photo || photo_area(preferred_photo) < photo_area(photo))
        preferred_photo = photo
      end
      # Delete unininteresting keys
      %w(downloadUrl parents userPermission lastModifyingUser labels selfLink etag owners owenerNamesspaces headRevisionId).each do |key|
        photo.delete(key)
      end
    end

    preferred_photo['preferred'] = true if preferred_photo
  end

  jj duplicated_photos_map
end

def photo_area(photo)
  photo_width(photo) * photo_height(photo)
end

def photo_width(photo)
  photo['imageMediaMetadata']['width']
end

def photo_height(photo)
  photo['imageMediaMetadata']['height']
end

def photo_key(photo)
  metadata = photo['imageMediaMetadata']
  filename = photo['originalFilename']
  return nil unless filename && metadata && metadata['date'] && metadata['date'] != '0000:00:00 00:00:00'
  "#{metadata['date']}:#{filename}"
end

def is_resizing(photos)
  return false unless photos.length == 2
  p1, p2 = photos

  asp1 = photo_width(p1) / photo_height(p1)
  asp2 = photo_width(p2) / photo_height(p2)

  approx_equals(asp1, asp2) || approx_equals(asp1, 1.0 / asp2)
end

def approx_equals(f1, f2, delta = 0.01)
  return (f1 - f2).abs < delta
end

main
