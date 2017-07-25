#!/usr/bin/env ruby

f = File.open('cloudfront.json.template').read
new_content = f.gsub('REPLACEME', Time.now.to_i.to_s)
File.write('cloudfront.json', new_content)
