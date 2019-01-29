#!/usr/bin/env ruby

require 'nokogiri'
require 'json'

dir = ARGV.shift.gsub(/\/+$/, '')
index = nil
media = []
Dir["#{dir}/media/*.json"].each do |file|
  id = JSON.parse(File.read(file))
  base = file.gsub(/\/media\/.*\.json$/, '')
  index = "#{base}/index.html"
  name = File.basename file
  media.push [name,id]
  puts "#{name}: #{id}"
end

nok = Nokogiri::HTML(File.read(index))
media.each do |pair|
  name, id = *pair
  if name =~ /slide(\d+)/
    slide_png = "img/Slide#{$1}.PNG"
    puts slide_png
    nok.xpath("//img[@src='#{slide_png}']").each do |img|
      div = img.parent
      div['style'] = "background-image: url(#{slide_png}); background-repeat: no-repeat; background-size: cover;"
      div.inner_html = "<iframe style=\"margin-top: 95px;\" width=\"650\" height=\"500\" src=\"https://www.youtube.com/embed/#{id}?modestbranding=1&autoplay=0&showinfo=0&controls=0\" frameborder=\"0\" allow=\"accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture\" allowfullscreen></iframe>"
    end
  end
end

File.open(index, "w") do |f|
  f.write nok.to_html
end
