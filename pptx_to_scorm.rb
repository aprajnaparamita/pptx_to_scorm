require 'zip'
require 'fileutils'
require 'mustache'
require 'json'

title = "Title"
description = "Description"

dir = ARGV.shift
dest = ARGV.shift
pptx = dir + "/presentation.pptx"
lis = []
STDERR.puts "Copy template => #{dest}"
FileUtils.cp_r "template", dest
Dir["#{dir}/*.PNG"].each do |file|
  STDERR.puts "Copy #{file} => #{dest}/img"
  FileUtils.cp file, "#{dest}/img"
  STDERR.puts "Creating thumb #{file} => #{dest}/img/thumb"
  name = file.split(/\//).last
  system "/usr/bin/convert", "-scale", "200x", file, "#{dest}/img/thumb/#{name}"
  lis.push name
end

ordered = lis.sort_by { |x| x[/\d+/].to_i }
slides = []
thumbs = []
images = []
ordered.each do |name|
  images.push "img/#{name}"
  images.push "img/thumb/#{name}"
  slide =<<SLIDE;
                <div class="tf_slide">
                    <img data-caption="Caption" src="img/#{name}" alt="#{name}" />
                </div>
SLIDE
  thumb =<<THUMB;
                    <div class="tf_thumb"><img src="img/thumb/#{name}"/></div>
THUMB
  slides.push slide
  thumbs.push thumb
end

puts images.to_json
list =<<TEMPLATE;
        <section id="third" class="clearfix tf_slider">
            <div class="tf_container">

                #{slides.join("\n\n")}

                <span id="left"></span>
                <span id="right"></span>

                <div id="tf_thumbs" class="">
                  #{thumbs.join("\n")}
                </div>

            </div>
    </section>
TEMPLATE

puts list

template_file = "#{dest}/index.html"
template = File.read template_file
STDERR.puts "Writing template file: #{template_file}"
template_out = Mustache.render(template, title: title, description: description, slides: list)
File.open(template_file, "w") do |f|
  f.write template_out
end

slides = {}
media = []

Zip::File.open(pptx) do |zip_file|
  zip_file.each do |entry|
    if entry.name =~ /^ppt\/media\/media/
      media.push entry.name
    end
    # content = entry.get_input_stream.read
  end
end

Zip::File.open(pptx) do |zip_file|
  zip_file.each do |entry|
    if entry.name =~ /^ppt\/slides\/_rels\//
      media.each do |file|
        search = file.gsub(/ppt\//, '')
        content = entry.get_input_stream.read
        slide = entry.name.split(/\//).last.split(/\./).first
        if content =~ /#{search}/
          puts "#{search} -> #{slide}"
          if slides.has_key? slide
            slides[slide].push file
          else
            slides[slide] = [file]
          end
        end
      end
    end
  end
end

files = {}
slides.each_key do |slide|
  slides[slide].each do |file|
    if files.has_key? file
      files[file].push slide
    else
      files[file] = [slide]
    end
  end
end

Zip::File.open(pptx) do |zip_file|
  zip_file.each do |entry|
    if files.has_key? entry.name
      files[entry.name].each_with_index do |slide,i|
        ext = entry.name.split(".").last
        media = "#{slide}_#{i}.#{ext}"
        puts "#{entry.name} -> #{dest}/media/#{media}"
        entry.extract(media)
        FileUtils.mv media, "#{dest}/media/"
      end
    end
    # content = entry.get_input_stream.read
  end
end
