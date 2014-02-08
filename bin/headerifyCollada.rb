#!/usr/bin/ruby

########################################################
# headerifyCollada.rb
#
# Creates a header from a .dae Collada file
#
# @author David Gavilan
#
########################################################
require "rexml/document"
include REXML # to use "Element"
$isChunky = true;
begin
	require "chunky_png"
rescue LoadError
	$isChunky = false;
end
	

########################################################
# globals
########################################################
$filename = ""
$outputfile = ""
$debugUVfile = ""
$h_guard = ""
$variableVertices = ""
$variableIndeces = ""
$vertices = []
$normals = []
$texcoord = []
$vcount = []
$polygons = []
$debug = false

########################################################
# Collada parsing
########################################################
def parseColladaFile(colladaFile)
	xmlfile = File.new(colladaFile)
	doc = REXML::Document.new(xmlfile)
	invert_axis = false
	doc.root.elements.each("asset/up_axis") {|up|
		if up.text == "Z_UP"
			invert_axis = true
		end
	}
	doc.root.elements.each("library_geometries/geometry/mesh") {|mesh|
		mesh.children.each do |child|
			if child.class!=Element # skip text lines
				next
			end
			if child.name == "source"
				if child.attributes['id'].include? "positions"
					child.children.each do |sc|
						if sc.class!=Element
							next
						end
						if sc.name == "float_array"
							$vertices = toVectorArray(sc.text.split(" ").map{|n| n.to_f}, 3)
							if invert_axis
								$vertices = invertAxis($vertices)
							end
							#puts $vertices.inspect
						end
					end
				end
				if child.attributes['id'].include? "normals"
					child.children.each do |sc|
						if sc.class!=Element
							next
						end
						if sc.name == "float_array"
							$normals = toVectorArray(sc.text.split(" ").map{|n| n.to_f}, 3)
							if invert_axis
								$normals = invertAxis($normals)
							end
						end
					end
				end
				if child.attributes['id'].include? "map"
					child.children.each do |sc|
						if sc.class!=Element
							next
						end
						if sc.name == "float_array"
							$texcoord = toVectorArray(sc.text.split(" ").map{|n| n.to_f}, 2)
						end
					end
				end
			elsif child.name == "polylist"
				child.children.each do |d|
					if d.class!=Element
						next
					end
					if d.name == "vcount"
						$vcount = d.text.split(" ").map { |n| n.to_i }
					end
					if d.name == "p"
						$polygons = toVectorArray(d.text.split(" ").map { |n| n.to_i }, 3)
					end
				end
			end
		end
	}
end

def findUVEquivalences(uvArray, textureWidth, textureHeight)
	hash = Hash.new
	equivalences = Array.new
	index = 0
	redundantCount = 0
	uvArray.each do |uv|
		i = (textureWidth * uv[0]).round.to_i
		j = textureHeight - (textureHeight * uv[1]).round.to_i 
		key = "#{i},#{j}"
		if hash[key].nil?
			hash[key] = index
			equivalences[index] = index
		else
			equivalences[index] = hash[key]
			redundantCount = redundantCount + 1
		end
		index = index + 1
	end
	if redundantCount > 0
		puts "Found #{redundantCount} redundant UV entries, out of #{uvArray.size}."
		if (redundantCount.to_f/uvArray.size.to_f)>= 0.25
			puts "You should consider reducing the number of UV loops in your model."
		end
	end
	return equivalences
end

def findPolygonEquivalences(polys, uvEquivalences)
	hash = Hash.new
	equivalences = Array.new
	index = 0
	redundantCount = 0
	polys.each do |p|
		uvIndex = p[2]
		uvIndex = uvEquivalences[uvIndex]
		key = "#{p[0]},#{p[1]},uvIndex"
		if hash[key].nil?
			hash[key] = index
			equivalences[index] = index
		else
			equivalences[index] = hash[key]
			redundantCount = redundantCount + 1
		end
		index = index + 1		
	end
	if redundantCount > 0
		puts "Found #{redundantCount} redundant vertices."
	end
	return equivalences
end

# a b c d e... -> {a, b} {c, d}  ...
def toVectorArray(array, stride)
	out = []
	i = 0
	j = 0
	array.each do |e|
		if out[i].nil?
			out[i] = []
		end
		out[i][j] = e
		j = j + 1
		if j % stride == 0
			j = 0
			i = i + 1
		end
	end
	return out
end

def invertAxis(vectorArray)
	out = []
	vectorArray.each do |v|
		vi = []
		vi[0] = v[0]
		vi[1] = v[2]
		vi[2] = -v[1]
		out << vi
	end
	return out
end

########################################################
# Create header
########################################################
def createHeader()
	begin
		file = File.open($outputfile, "w")
		file.puts "/**\n * @file #{$outputfile}"
		file.puts " */" 
		file.puts "\#ifndef #{$h_guard}"
		file.puts "\#define #{$h_guard}\n\n"
		# vertices
		file.puts "static const vertexDataTextured #{$variableVertices}[] = {"
		$polygons.each do |p|
			v = $vertices[p[0]]
			n = $normals[p[1]]
			t = $texcoord[p[2]]
			file.puts "{ {#{v[0]}f, #{v[1]}f, #{v[2]}f}, {#{n[0]}f, #{n[1]}f, #{n[2]}f}, {#{t[0]}, #{t[1]}} }, "
		end
		file.puts "};\n"
		# indeces
		file.puts "static const GLushort #{$variableIndeces}[] = {"
		i = 0
		$vcount.each do |c|
			if c == 3 # triangle
				file.write "#{i}, #{i+1}, #{i+2},  "
			elsif c == 4 # quad
				file.write "#{i}, #{i+1}, #{i+2}, #{i}, #{i+2}, #{i+3},  "
			else
				puts "#{c}-gons not supported. Only triangles and quads"
			end
			i = i + c
		end
		file.puts "\n};\n"

		file.puts "\#endif // #{$h_guard}"
	rescue IOError => e
		#some error occur, dir not writable etc.
	ensure
		file.close unless file == nil
	end
end


########################################################
# Debug UVs
########################################################
def createDebugUVImage(width, height, filename)
	png = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)
	$texcoord.each do |uv|
		i = (width * uv[0]).round.to_i
		j = height - (height * uv[1]).round.to_i
		if i >= width || j >= height
			puts "Out of bounds: #{i}, #{j}"
		end
		if png[i, j] != 0
			# duplicate vertex
			png[i, j] = ChunkyPNG::Color(255,0,0,255)
		else
			png[i, j] = ChunkyPNG::Color(0,255,0,255)
		end
	end
	#puts $texcoord.size.to_s + " vertices"
	png.save(filename, :interlace => false)
end

########################################################
# setup
########################################################

def parseParameters()
	if ARGV.size < 1
		puts "#{__FILE__} filename [-debug]"
		exit(0)
	end
	$filename = ARGV[0]

	if !File.exists?($filename)
		puts $filename + " doesn't exist."
		exit(0)
	end

	if ARGV[1] == "-debug"
		$debug = true
	end

	basename = File.basename($filename, File.extname( $filename ) )
	# find unique output filename (avoid overwriting existing files)
	interfix = 0
	begin
		suffix = interfix > 0 ? "_" + interfix.to_s + ".h" : ".h"
		$outputfile = basename + suffix
		interfix += 1
	end while File.exists?($outputfile)
	$debugUVfile = basename + interfix.to_s + ".png"

	# strings for code generation
	basenameWithUnderscores = basename.gsub(/[\s-]/, '_') 
	$h_guard = "MODEL_"+ basenameWithUnderscores.upcase+"_H_"
	$variableVertices = "g_#{basename}Vertices"
	$variableIndeces = "g_#{basename}Indeces"
end

########################################################
# Main
########################################################
if __FILE__ == $0 # when included as a lib, this code won't execute :)
	parseParameters()
	parseColladaFile($filename)
	#createHeader()
	#puts "File saved to #{$outputfile}"
	if $debug && $isChunky
		# Just to get an idea of how many UV coordinates are redundant.
		uvEquivalences = findUVEquivalences($texcoord, 256, 256)
		polyEquivalences = findPolygonEquivalences($polygons, uvEquivalences)
		createDebugUVImage(128, 128, $debugUVfile)
		puts "Debug UV image saved to #{$debugUVfile}"
	end
end
