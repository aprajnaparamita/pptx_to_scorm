#!/usr/bin/env ruby

require 'fileutils'
require 'open3'

# This script runs on a Windows machine with Microsoft Powerpoint installed
# Save all powerpoint slides to a series of PNG files of each slide
# It takes two arguments

file = ARGV.shift
puts file

dir = File.basename(file, '.pptx')
dir.gsub!(/ +/, ' ')
dir.strip!
dir = ARGV.shift # "C:/Users/janet/Desktop/powerpoint/export/#{dir}"
puts dir

FileUtils.mkdir_p dir
file.gsub!(/\//, '\\')
dir.gsub!(/\//, '\\')

vbs =<<END;
Dim oPPT
Dim oPPTDoc
Dim sPath
Dim sOutput

sPath = "#{file}"
sOutput = "#{dir}"

WScript.StdOut.WriteLine "Exporting..."
WScript.StdOut.WriteLine sPath
WScript.StdOut.WriteLine sOutput

Set oPPT = WScript.CreateObject("PowerPoint.Application")
oPPT.Visible = TRUE
WScript.StdOut.WriteLine "Opening..."
Set oPPTDoc=oPPT.Presentations.Open(sPath)
WScript.StdOut.WriteLine "Exporting..."
oPPTDoc.Export sOutput,"PNG", 1024, 768
WScript.StdOut.WriteLine "Close..."
oPPTDoc.Close
Set oPPTDoc = Nothing
oPPT.Quit
set oPPT = Nothing
WScript.StdOut.WriteLine "Export Complete"
WScript.Quit
END

File.open("export.vbs", "w") do |f|
  f.write vbs
end

stdin, stdout, stderr = Open3.popen3('cscript export.vbs')
puts stdout.readlines

puts "Copying PPTX to #{dir}/presentation.pptx for scorm creator"
FileUtils.cp file, "#{dir}/presentation.pptx"
