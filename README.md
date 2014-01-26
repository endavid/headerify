headerify
==========

A collection of scripts to convert different types of formats into simple C headers.

TexturePackerExporters
=======================
* Install this as an exporter to TexturePacker to create header file definitions for your textures: http://www.codeandweb.com/texturepacker/documentation#customization

bin/headerifyCollada.rb
========================
* Converts the geometry inside .dae Collada files to C syntax.
* I use it to convert files exported from Blender to data directly usabe in OpenGL. 
* When the up axis is set to Z (Blender exporter), axis are converted to OpenGL (y'=z, z'=-y)   

bin/headerifyFont.rb
=====================
* Converts .FNT bitmap fonts definitions to C syntax.
* For instance, I use bmGlyph to create the .FNT file, and then convert it with this script.
 * http://www.bmglyph.com/
* Check the sample definitions included in the "headers" folder.

bin/stringifyLocalizedCSV.rb
==============================
* This script creates .strings files from Comma-Separated Values. I use it for localization.
* It assumes that the first line is something like:

```
    #id,en_US,es_ES,ja_JP,ca_ES
```

* Then, it will generate a different .strings file for each definition. Eg.

```bash
    ruby bin/stringifyLocalizedCSV.rb Sheet.csv
```

* will generate these files: Sheet_en_US.strings, Sheet_es_ES.strings, ... etc.


License
=======
MIT License

Copyright (C) 2013 David Gavilan Ruiz
 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
