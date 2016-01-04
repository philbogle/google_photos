#!/usr/bin/env ruby
#
# Command line utlity for dumping potentially duplicate photos based on various heuristics.
#
# dups: photos which have the same name, date, location, and camera model
# resize: photos which have the same name, date, location, camera model, and aspect ratio.
# iphonehdr:

require 'json'
require 'pp'

def main()
  if ARGV.length != 2
    puts "Usage: ./dump_dups FILENAME (resize|dups|simultaenous)"
    raise "Invalid usage"
  end

  filename = ARGV.shift
  mode = ARGV.shift

  photo_map = {}
  for line in File.open(filename)
    photo = JSON.parse(line)

    # Skip trashed and hidden photos
    next if photo['labels'] && (photo['labels']['trashed'] || photo['labels']['hidden'])

    key = photo_key(photo, mode)
    next if !key
    (photo_map[key] ||= []) << photo
  end

  duplicated_photos_map =
    case mode
    when 'iphonehdr'
      photo_map.select {|key, photos| photos.length == 2 && is_resizing(photos)}
    when 'dups'
      photo_map.select {|key, photos| photos.length > 1}
    when 'resize'
      photo_map.select {|key, photos| is_resizing(photos)}
    else
      raise "Unexpected mode #{mode}"
    end

  duplicated_photos_map.each do |key, photos|
    preferred_photo = nil
    photos.each do |photo|
      id = photo['id']
      # Fix thumbnail link to a permanently valid link.  (The URL generated in the API is only valid for a short time.)
      photo['thumbnailLink'] = "https://drive.google.com/thumbnail?authuser=0&sz=w320&id=#{id}"

      case mode
      when 'resize'
        if (!preferred_photo || photo_area(preferred_photo) < photo_area(photo))
          preferred_photo = photo
        end
      when 'iphonehdr'
        if (!preferred_photo || preferred_photo['title'] > photo['title'])
          preferred_photo = photo
        end
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

def photo_aspect(photo)
  photo_width(photo).to_f / photo_height(photo)
end

def photo_width(photo)
  photo['imageMediaMetadata']['width']
end

def photo_height(photo)
  photo['imageMediaMetadata']['height']
end

def photo_key(photo, mode)
  metadata = photo['imageMediaMetadata']
  filename = photo['originalFilename']
  return nil unless filename && metadata && metadata['date']

  date = metadata['date']
  return nil if date == '0000:00:00 00:00:00'
  return nil if mode == 'iphonehdr' && metadata['cameraModel'] !~ /iPhone/

  # Normalize a file name like "foo-001.jpg" to "foo.jpg"
  filename = filename.gsub(/-00[0-9](?=\.jpg)/, '')

  # Normalize a file name like "foo (1).jpg" to "foo.jpg"
  filename = filename.gsub(/\s*\([0-9]\)(?=\.jpg)/, '')
  case mode
  when 'iphonehdr'
    [metadata['date'], metadata['cameraModel'], metadata['location']].join(':')
  else
    [metadata['date'], filename, metadata['cameraModel'], metadata['location']].join(':')
  end
end

def is_resizing(photos)
  return false unless photos.length >= 2

  p0 = photos[0]
  asp = photo_aspect(p0)

  for i in (1..(photos.length-1))
    asp_i = photo_aspect(photos[i])
    return false unless approx_equals(asp_i, asp) || approx_equals(asp_i, 1.0 / asp)
  end

  true
end

def approx_equals(f1, f2, delta = 0.01)
  return (f1 - f2).abs < delta
end

main
