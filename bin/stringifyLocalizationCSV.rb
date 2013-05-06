# coding=utf-8 
#!/usr/bin/ruby

########################################################
# stringifyLocalizedCSV.rb
#
# Creates .strings files from a CSV file, 
# where the first line is something like:
#   #id,en_US,es_ES,ja_JP,ca_ES
#
# @author David Gavilan
#
########################################################

require 'csv'

########################################################
# globals
########################################################
$filename = ""


########################################################
# parsing
########################################################
def parseCSVFile(filename)
	basename = File.basename($filename, File.extname( $filename ) )

	begin
		outputFiles = []

		lines = CSV.read(filename) 
		locales = lines[0][1..-1]
		puts "Locales: "+locales.inspect
		# open files for writing (en_US, ja_JP => FILE_en_US.strings, FILE_ja_JP.strings)
		i=0
		locales.each do |locale|
			output_filename = basename + "_" + locale + ".strings"
			outputFiles[i] = File.open(output_filename, "w")
			i+=1
		end
		lines[1..-1].each do |line|
			i = 0
			outputFiles.each do |file|
				i += 1
				if file == nil
					next
				end
				file.puts "\""+line[0].to_s+"\" = \""+line[i].to_s+"\";"
			end
		end
	rescue IOError => e
		#some error occur, dir not writable etc.
	ensure
		outputFiles.each do |file|
			file.close unless file == nil
		end
	end

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
end

########################################################
# Main
########################################################
if __FILE__ == $0 # when included as a lib, this code won't execute :)
	parseParameters()
	parseCSVFile($filename)
end
