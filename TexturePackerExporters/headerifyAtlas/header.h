/* 
 * TextureAtlas definition header file.
 * Created with TexturePacker (http://www.texturepacker.com)
 * Headerify exporter: github.com/endavid
 * 
 * {{smartUpdateKey}}
 */
#ifndef {{texture.trimmedName}}_H_
#define {{texture.trimmedName}}_H_

struct SpriteDef {
	const char* 	name;
	int				x;
	int				y;
	int				width;
	int				height;
};

struct TextureAtlasDef {
	const char*			name;
	int					width;
	int					height;
	const SpriteDef*	sprites;
};

namespace {
	SpriteDef g_spriteList[] = {
	{% for sprite in allSprites %}	{ "{{sprite.trimmedName}}", {{sprite.frameRect.x}}, {{sprite.frameRect.y}}, {{sprite.frameRect.width}}, {{sprite.frameRect.height}} }{% if not forloop.last %}, {% endif %}
	{% endfor %}
	};
}

TextureAtlasDef g_textureAtlas = {
	"{{texture.trimmedName}}",
	{{texture.size.width}},
	{{texture.size.height}},
	&g_spriteList[0]
};

#endif // {{texture.trimmedName}}_H_
