#!/usr/bin/ruby

########################################################
# headerifyFont.rb
#
# Creates a header from a Fnt file
#
# @author David Gavilan
#
########################################################

########################################################
# globals
########################################################
$filename = ""
$outputfile = ""
$font = Hash.new
$charList = Hash.new
$h_guard = ""


########################################################
# parsing
########################################################
def parseFontFile(fontfile)
	File.readlines(fontfile).each do |line|
		if line.start_with?("info ")
			$font["face"] = line[/face=(\"[A-Za-z0-9_\s]*\")/,1]
			$font["charset"] = line[/charset=(\"[A-Za-z0-9_\s]*\")/,1]
			$font["size"] = line[/size=([0-9]+)/,1]
			$font["bold"] = line[/bold=([0-9]+)/,1]
			$font["italic"] = line[/bold=([0-9]+)/,1]
			$font["unicode"] = line[/unicode=([0-9]+)/,1]
			$font["stretchH"] = line[/stretchH=([0-9]+)/,1]
			$font["smooth"] = line[/smooth=([0-9]+)/,1]
			$font["aa"] = line[/aa=([0-9]+)/,1]
			$font["padding"] = line[/padding=([0-9,]+)/,1]
			$font["spacing"] = line[/spacing=([0-9,]+)/,1]
		elsif line.start_with?("common ")
			$font["lineHeight"] = line[/lineHeight=([0-9]+)/,1]
			$font["base"] = line[/base=([0-9]+)/,1]
			$font["scaleW"] = line[/scaleW=([0-9]+)/,1]
			$font["scaleH"] = line[/scaleH=([0-9]+)/,1]
		elsif line.start_with?("page ")
			$font["file"] = line[/file=(\"[A-Za-z0-9_\s\.\-]*\")/,1]
		elsif line.start_with?("chars ")
			$font["count"] = line[/count=([0-9]+)/,1]
		elsif line.start_with?("char ")
			key = line[/id=([0-9]+)/,1]
			$charList[key] = Hash.new
			$charList[key]["x"] = line[/x=([0-9]+)/,1]
			$charList[key]["y"] = line[/y=([0-9]+)/,1]
			$charList[key]["width"] = line[/width=([0-9]+)/,1]
			$charList[key]["height"] = line[/height=([0-9]+)/,1]
			$charList[key]["xoffset"] = line[/xoffset=(-?[0-9]+)/,1]
			$charList[key]["yoffset"] = line[/yoffset=(-?[0-9]+)/,1]
			$charList[key]["xadvance"] = line[/xadvance=([0-9]+)/,1]
		end
	end
	# sort
	$charList = $charList.sort_by { |k, v| k.to_i }
end

def createHeader()
	begin
		file = File.open($outputfile, "w")
		file.puts "\#ifndef #{$h_guard}"
		file.puts "\#define #{$h_guard}\n\n"
		file.puts "\#include \"ui/FontDef.h\"\n\nnamespace {"
		file.puts "\tvd::ui::UniChar g_chars[] = {"
		file.puts "\t\t{ 0, 0, 0, 0, 0, 0, 0, 0 }, // default for missing keys"
		$charList.each {|key, value|
			x = value["x"]
			y = value["y"]
			w = value["width"]
			h = value["height"]
			xo = value["xoffset"]
			yo = value["yoffset"]
			xa = value["xadvance"]
			file.puts "\t\t{ #{key} /*id*/, #{x} /*x*/, #{y} /*y*/, #{w} /*w*/, #{h} /*h*/, #{xo} /*xo*/, #{yo} /*yo*/, #{xa} /*xa*/},"
		}
		file.puts "\t};\n}\n\n"

		file.puts "vd::ui::FontDesc g_font = {"
		file.puts "\t#{$font['file']}, // file"
		file.puts "\t#{$font['face']}, // face"
		file.puts "\t#{$font['charset']}, // charset"
		file.puts "\t#{$font['size']}, // size"
		file.puts "\t#{$font['stretchH']}, // stretchH"
		file.puts "\t#{$font['bold']==1}, // bold"
		file.puts "\t#{$font['italic']==1}, // italic"
		file.puts "\t#{$font['unicode']==1}, // unicode"
		file.puts "\t#{$font['smooth']==1}, // smooth"
		file.puts "\t#{$font['aa']==1}, // aa"
		file.puts "\tvd::math::Vector4(#{$font['padding']}), // padding"
		file.puts "\tvd::math::Vector2(#{$font['spacing']}), // spacing"
		file.puts "\t#{$font['lineHeight']}, // lineHeight"
		file.puts "\t#{$font['base']}, // base"
		file.puts "\t#{$font['scaleW']}, // scaleW"
		file.puts "\t#{$font['scaleH']}, // scaleH"
		file.puts "\t#{$font['count']}, // charCount"
		file.puts "\t&g_chars[0]\n};\n\n"

		file.puts "\#endif // #{$h_guard}"
	rescue IOError => e
		#some error occur, dir not writable etc.
	ensure
		file.close unless file == nil
	end

# 
#	$font.each {|key, value| 
#		puts "#{key} is #{value}" 
#	}
#	$charList.each {|key, value| 
#		value.each {|k, v|
#			puts "#{key}: #{k} is #{v}"
#		}
#	}
end

########################################################
# setup
########################################################

def parseParameters()
	if ARGV.size != 1
		puts "#{__FILE__} filename"
		exit(0)
	end
	$filename = ARGV[0]

	if !File.exists?($filename)
		puts $filename + " doesn't exist."
		exit(0)
	end

	basename = File.basename($filename, File.extname( $filename ) )
	# find unique output filename (avoid overwriting existing files)
	interfix = 0
	begin
		suffix = interfix > 0 ? "_" + interfix.to_s + ".h" : ".h"
		$outputfile = basename + suffix
		interfix += 1
	end while File.exists?($outputfile)

	# strings for code generation
	basenameWithUnderscores = basename.gsub(/[\s-]/, '_') 
	$h_guard = "DATA_"+ basenameWithUnderscores.upcase+"_H_"
end

########################################################
# Main
########################################################
if __FILE__ == $0 # when included as a lib, this code won't execute :)
	parseParameters()
	parseFontFile($filename)
	createHeader()
	puts "File saved to #{$outputfile}"
end
