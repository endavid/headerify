#!/usr/bin/ruby

########################################################
# headerifyCollada.rb
#
# Creates a header from a .dae Collada file
#
# @author David Gavilan
#
########################################################
require "optparse" # to parse arguments
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
$variableNames = { vertices: "Vertices", indices: "Indices", bindShapeM: "BindShapeMatrix", jointCount: "JointCount", boneCount: "BoneCount", invBindM: "InverseBindMatrices", jTT: "JointTransformTree", jointIndices: "JointToSkeletonIndices", animation: "AnimationData", keyframes: "Keyframes", matrices: "Matrices" }
$vertices = []
$normals = []
$texcoord = []
$vcount = []
$polygons = []
$bindShapeMatrix = []
$jointCount = 0
$jointNames = []
$invBindMatrices = []
$weightArray = []
$skeleton = {}
$skeletonNodeNames = []
$jointIndexToSkeletonIndex = []
$animations = {}
$debug = false
$force = true

########################################################
# Collada parsing
# 	Assume there's only one mesh,
#	and if there's a skin and a skeletal animation, 
#	assume it belongs to that mesh.
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
				numInputs = 0
				child.children.each do |d|
					if d.class!=Element
						next
					end
					if d.name == "input"
						# count number of inputs for the mapping
						numInputs = numInputs + 1
					end
					if d.name == "vcount"
						$vcount = d.text.split(" ").map { |n| n.to_i }
					end
					if d.name == "p"
						$polygons = toVectorArray(d.text.split(" ").map { |n| n.to_i }, numInputs)
					end
				end
			end
		end
	}
	# For skinned models (data will be empty otherwise)
	weights = []
	doc.root.elements.each("library_controllers/controller/skin") {|skin|
		skin.children.each do |child|
			if child.class!=Element # skip text lines
				next
			end
			if child.name == "bind_shape_matrix"
				$bindShapeMatrix = child.text.split(" ").map{|n| n.to_f}
			elsif child.name == "source"
				if child.attributes['id'].include? "joints"
					# find boneCount and bone names
					child.children.each do |sc|
						if sc.class!=Element
							next
						end
						if sc.name == "Name_array"
							$jointNames = sc.text.split(" ")
							$jointCount = sc.attributes['count'].to_i
						end
					end
				elsif child.attributes['id'].include? "bind_poses"
					# find the inverse bind matrices
					child.children.each do |sc|
						if sc.class!=Element
							next
						end
						if sc.name == "float_array"
							# count = sc.attributes['count'].to_i
							$invBindMatrices = toVectorArray(sc.text.split(" ").map{|n| n.to_f}, 16)
						end
					end
				elsif child.attributes['id'].include? "weights"
					child.children.each do |sc|
						if sc.class!=Element
							next
						end
						if sc.name == "float_array"
							# count = sc.attributes['count'].to_i
							weights = sc.text.split(" ").map{|n| n.to_f}
						end
					end
				end	
			elsif child.name == "vertex_weights"
				numInputs = 0
				vcountWeights = []
				jointWeightIndices = []
				child.children.each do |d|
					if d.class!=Element
						next
					end
					if d.name == "input"
						# count number of inputs for the mapping
						numInputs = numInputs + 1
					end
					if d.name == "vcount"
						vcountWeights = d.text.split(" ").map { |n| n.to_i }
					end
					if d.name == "v"
						jointWeightIndices = toVectorArray(d.text.split(" ").map { |n| n.to_i }, numInputs)
					end
				end
				$weightArray = mapWeightsPerVertex(vcountWeights, jointWeightIndices, weights)
			end
		end
	}
	doc.root.elements.each("library_visual_scenes/visual_scene/node") {|node|
		if node.attributes['id'] == "Armature"
			$skeleton = extractBoneTree(node, "")
			boneIndex = 0
			$skeleton.each{|k, v|
				$skeletonNodeNames << k
				jointIndex = $jointNames.index(k)
				if !jointIndex.nil?
					$jointIndexToSkeletonIndex[jointIndex] = boneIndex
				end
				boneIndex += 1
			}
			#puts $skeletonNodeNames.inspect
			#puts $skeleton.inspect
			#puts $jointIndexToSkeletonIndex.inspect
		end
	}
	# animations of the bones in the skeleton
	doc.root.elements.each("library_animations/animation") {|anim|
		boneId = /Armature_(.+)_pose_matrix/.match(anim.attributes['id'])[1]
		boneIndex = $skeletonNodeNames.index(boneId)
		if !boneId.nil?
			animationNode = {keyframes: [], matrices: []}
			anim.children.each do |child|
				if child.class!=Element # skip text lines
					next
				end
				if child.name == "source"
					if child.attributes['id'].include? "matrix-input"
						# keyframes
						child.children.each do |sc|
							if sc.class!=Element
								next
							end
							if sc.name == "float_array"
								# count = sc.attributes['count'].to_i
								animationNode[:keyframes] = sc.text.split(" ").map{|n| n.to_f}
							end
						end
					elsif child.attributes['id'].include? "matrix-output"
						# interpolation matrices
						child.children.each do |sc|
							if sc.class!=Element
								next
							end
							if sc.name == "float_array"
								# count = sc.attributes['count'].to_i
								animationNode[:matrices] = toVectorArray(sc.text.split(" ").map{|n| n.to_f}, 16)
							end
						end
					end
					# don't check interpolation node. Assume LINEAR for all.
				end # source
			end # child
			$animations[boneId] = animationNode
		end # boneId != nil
	}

	#puts $weightArray.inspect
	#puts $bindShapeMatrix.inspect
	#puts $invBindMatrices.inspect
	#puts $animations.inspect
end

def extractBoneTree(node, parentId)
	h = {}
	nodeId = node.attributes['id']
	node.children.each do |child|
		if child.class!=Element # skip text lines
			next
		end
		if child.name == "matrix"
			matrix = child.text.split(" ").map{|n| n.to_f}
			h[nodeId] = {transform: matrix, parentId: parentId}
		elsif child.name == "node"
			h.merge!(extractBoneTree(child, nodeId))
		end
	end
	return h
end

# same UVs?
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
	return {:equivalences => equivalences, :redundant => redundantCount}
end

# same polygons?
def findPolygonEquivalences(polys, uvEquivalences)
	hash = Hash.new
	equivalences = Array.new
	index = 0
	redundantCount = 0
	polys.each do |p|
		uvIndex = p[2]
		if uvIndex.nil? # missing UV coords
			uvIndex = 0
		end
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
	return {:equivalences => equivalences, :redundant => redundantCount}
end

# create a hash to access weights more easily
def mapWeightsPerVertex(vcount, v, weights)
	moreThan3Count = 0
	iV = 0
	iWeightArray = 0
	weightArray = []
	vcount.each do |jointsPerVertex|
		if jointsPerVertex > 3
			moreThan3Count += 1
		end
		jointWeightPairs = []
		for j in 0..(jointsPerVertex-1)
			if j <= 3 # if there are more joints, ignore
				jointIndex = v[iV][0]
				weightIndex = v[iV][1]
				weight = weights[weightIndex]
				jointWeightPairs[j] = [jointIndex, weight]
			end
			iV += 1
		end
		weightArray[iWeightArray] = jointWeightPairs
		iWeightArray += 1
	end
	if moreThan3Count > 0
		puts "There are #{moreThan3Count} vertices with more than 3 joint contributions! Ignoring the 4th joint onwards..."
	end
	return weightArray
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

# Convert Blender coordinates to OpenGL coordinates
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
# Printing functions
########################################################
# 1, 0.5, 1 -> "{1f, 0.5f, 1f}"
def printVector(v)
	return "{" + (v.map{|n| "#{n.to_s}f"}.join(', ')) + "}"
end
# 1, 2, 1 -> "{1, 2, 1}"
def printVectorInt(v)
	return "{" + (v.map{|n| "#{n}"}.join(', ')) + "}"
end
# 1, 0.5, 1, ... -> "math::Matrix(1f, 0.5f, 1f, ...)"
def printMatrix(m)
	return "math::Matrix4(" + (m.map{|n| "#{n}f"}.join(', ')) + ")"
end
# several lines of math::Matrix(...) data
def printMatrices(mm)
	return mm.map{|m| "\t"+printMatrix(m)}.join(",\n")
end

########################################################
# Create header
########################################################
def createHeader(equivalences)
	begin
		file = File.open($outputfile, "w")
		file.puts "/**\n * @file #{$outputfile}"
		file.puts " */" 
		file.puts "\#ifndef #{$h_guard}"
		file.puts "\#define #{$h_guard}\n\n"

		datatype = "vertexDataTextured"
		if $jointCount > 0
			datatype = "vertexDataSkinned"
		end

		# vertices
		file.puts "static const #{datatype} #{$variableNames[:vertices]}[] = {"
		index = 0
		numVerts = 0
		indexRef = Array.new
		$polygons.each do |p|
			if equivalences[index] == index # unique references only
				v = $vertices[p[0]]
				n = $normals[p[1]]
				t = [0.0, 0.0] # default texcoord for models without UVs
				if !p[2].nil?
					if !$texcoord[p[2]].nil?
						t = $texcoord[p[2]]
					end
				end
				if v.nil?
					puts "Null vertex!"
					next
				end
				file.write "\t{ " + printVector(v) + ", " + printVector(n) + ", " + printVector(t)
				if $jointCount > 0
					w = [1.0, 0.0, 0.0] # weights of the joints
					joints = [0, 0, 0, 0]
					wj = $weightArray[p[0]]
					wji = 0
					wj.each do |jointWeightPair|
						if wji < 3
							joints[wji] = jointWeightPair[0]
							w[wji] = jointWeightPair[1]
						end
						wji += 1
					end
					file.write ", "+printVector(w)+", "+printVectorInt(joints)
				end
				file.write " }, \n"
				indexRef[index] = numVerts
				numVerts = numVerts + 1
			else
				indexRef[index] = indexRef[equivalences[index]]
			end
			index = index + 1
		end
		file.puts "};\n"
		# indices
		file.puts "static const GLushort #{$variableNames[:indices]}[] = {"
		i = 0
		$vcount.each do |c|
			if c == 3 # triangle
				file.write "#{indexRef[i]}, #{indexRef[i+1]}, #{indexRef[i+2]},  "
			elsif c == 4 # quad
				file.write "#{indexRef[i]}, #{indexRef[i+1]}, #{indexRef[i+2]}, #{indexRef[i]}, #{indexRef[i+2]}, #{indexRef[i+3]},  "
			else
				puts "#{c}-gons not supported. Only triangles and quads"
			end
			i = i + c
		end
		file.puts "\n};\n"

		#skinned mesh?
		if $jointCount > 0
			file.write "\n// Skinned Mesh Data\n//--------------------------------------\n"
			file.write "static const math::Matrix4 #{$variableNames[:bindShapeM]} = " + printMatrix($bindShapeMatrix) + ";\n"
			file.write "static const uint16_t #{$variableNames[:boneCount]} = #{$skeletonNodeNames.size};\n";
			file.write "static const uint16_t #{$variableNames[:jointCount]} = #{$jointCount};\n"
			file.write "// Bone names: #{$jointNames.join(', ')}\n\n"
			file.write "static const math::Matrix4 #{$variableNames[:invBindM]}[] = {\n" + printMatrices($invBindMatrices) + "\n};\n"
			file.write "static struct core::TreeNode<math::Matrix4> #{$variableNames[:jTT]}[] = {\n"
			$skeleton.each{|k, v|
				i = $skeletonNodeNames.index(k)
				parentIndex = $skeletonNodeNames.index(v[:parentId])
				if parentIndex.nil? # when a node has no parent, it's denoted by pointing to itself
					parentIndex = i
				end
				file.write("\t/*#{i}: #{k}*/{#{parentIndex}, " + printMatrix(v[:transform]) + "}, \n")
			}
			file.write "};\n"
			file.write "static const uint16_t #{$variableNames[:jointIndices]}[] = " + printVectorInt($jointIndexToSkeletonIndex) + ";\n\n"
			file.write "// Animation of each bone {keyframeCount, keyframeArray, Matrix4array}\n"
			$animations.each do |k, v|
				boneId = k
				# convert secs to millisecs
				file.write "static const float #{$variableNames[:keyframes]}_#{boneId}[] = " + printVector(v[:keyframes].map{|n| 1000 * n}) + ";\n"
				file.write "static const math::Matrix4 #{$variableNames[:matrices]}_#{boneId}[] = {\n" + printMatrices(v[:matrices]) + "};\n"
			end
			file.write "static const gfx::MatrixAnimData #{$variableNames[:animation]}[] = {\n"
			$skeletonNodeNames.each do |boneId| # place them in the same order!
				keyframeCount = 0
				keyframes = "NULL"
				animationMatrices = "NULL"
				animationNode = $animations[boneId]
				if !animationNode.nil?
					keyframeCount = animationNode[:keyframes].size
					keyframes = "#{$variableNames[:keyframes]}_#{boneId}"
					animationMatrices = "#{$variableNames[:matrices]}_#{boneId}"
				end
				file.write "\t{ #{keyframeCount}, #{keyframes}, #{animationMatrices} },\n"
			end
			file.write "};\n\n"

		end # skinned mesh

		# end header
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
			i = i % width
			j = j % height
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

def parseParametersTest()
	opt_parser = OptionParser.new do |opts|
		opts.banner = "Usage: #{__FILE__} [options]"
		opts.separator ""
		opts.separator "Specific options:"
		opts.on("-d", "--debug", "Generate a PNG file with UVs") do |v|
			$debug = true
		end
		opts.on("-f", "--force", "Overwrites any existing header file") do |v|
			$force = true
		end
	end
	opt_parser.parse(ARGV)
	puts ARGV.inspect
end

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

	if $force
		$outputfile = basename + ".h"
		$debugUVfile = basename + ".png"
	else
		# find unique output filename (avoid overwriting existing files)
		interfix = 0
		begin
			suffix = interfix > 0 ? "_" + interfix.to_s + ".h" : ".h"
			$outputfile = basename + suffix
			interfix += 1
		end while File.exists?($outputfile)
		$debugUVfile = basename + interfix.to_s + ".png"
	end

	# strings for code generation
	basenameWithUnderscores = basename.gsub(/[\s-]/, '_') 
	$h_guard = "MODEL_"+ basenameWithUnderscores.upcase+"_H_"
	# add g_modelName to the variable names
	$variableNames.each do |key, value|
		$variableNames[key] = "g_#{basename}#{value}"
	end
end

########################################################
# Main
########################################################
if __FILE__ == $0 # when included as a lib, this code won't execute :)
	parseParameters()
	parseColladaFile($filename)	
	uvEq = findUVEquivalences($texcoord, 256, 256)
	polyEq = findPolygonEquivalences($polygons, uvEq[:equivalences])
	if uvEq[:redundant] > 0
		puts "Found #{uvEq[:redundant]} redundant UV entries, out of #{$texcoord.size}."
	end
	if polyEq[:redundant] > 0
		puts "Removed #{uvEq[:redundant]} redundant vertices."
	end
	if ((uvEq[:redundant]-polyEq[:redundant]).to_f/$texcoord.size.to_f)>= 0.25
		puts "You should consider reducing the number of UV loops in your model."
	end
	createHeader(polyEq[:equivalences])
	puts "File saved to #{$outputfile}"
	if $debug && $isChunky
		createDebugUVImage(128, 128, $debugUVfile)
		puts "Debug UV image saved to #{$debugUVfile}"
	end
end
