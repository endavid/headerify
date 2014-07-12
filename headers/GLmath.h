/** @file GLmath.h
	@author David Gavilan
	@date 7/1/10.
 */
// Copyright (C) 2010-2014 David Gavilan Ruiz. MIT License.


#ifndef GFX_GL_MATH_H_
#define GFX_GL_MATH_H_

#include "gfx/gfx_def.h"
#include "math/Vector.h"
#include "math/Matrix.h"
#include "gfx/Color.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

GFX_NS_BEGIN	
    
// --------------------------------------------------------
// This data is defined after MC3D, to be able to use the 
// Blender export script.
// --------------------------------------------------------
struct texCoord {
    GLfloat		u;
    GLfloat		v;
    
    inline texCoord& operator=(const math::Vector2& rhs) {
        u = rhs.GetX();
        v = rhs.GetY();
        return *this;
    }
};
typedef struct texCoord texCoord;
typedef texCoord* texCoordPtr;

struct vec2
{
    GLfloat     x;
    GLfloat     y;
    
    inline vec2& operator=(const math::Vector2& rhs) {
        x = rhs.GetX();
        y = rhs.GetY();
        return *this;
    }
};

struct vec3
{
    GLfloat x;
    GLfloat y;
    GLfloat z;
    
    inline vec3& operator=(const math::Vector3& rhs) {
        x = rhs.GetX();
        y = rhs.GetY();
        z = rhs.GetZ();
        return *this;
    }
    
};

struct vec4
{
    GLfloat x;
    GLfloat y;
    GLfloat z;
    GLfloat w;
    
    inline vec4& operator=(const math::Vector4& rhs) {
        x = rhs.GetX();
        y = rhs.GetY();
        z = rhs.GetZ();
        w = rhs.GetW();
        return *this;
    }
    
};
struct colorRGBA
{
    GLubyte r;
    GLubyte g;
    GLubyte b;
    GLubyte a;
    
    inline colorRGBA& operator=(const math::Vector4& rhs) {
        r = rhs.GetX();
        g = rhs.GetY();
        b = rhs.GetZ();
        a = rhs.GetW();
        return *this;
    }
    inline colorRGBA& operator=(const ColorLDR& color) {
        uint32_t rhs = color.GetAsUInt32();
        r = (rhs >> 24);
        g = (0x000000ff & (rhs >> 16));
        b = (0x000000ff & (rhs >> 8));
        a = (0x000000ff & rhs);
        return *this;
    }
    inline void Set(GLubyte r, GLubyte g, GLubyte b, GLubyte a) {
        this->r = r; this->g = g; this->b = b; this->a = a;
    }
};
        
typedef struct vec3 vec3;
typedef vec3* vec3Ptr;
typedef struct vec4 vec4;
typedef vec4* vec4Ptr;


struct byteVec4
{
    unsigned char x;
    unsigned char y;
    unsigned char z;
    unsigned char w;
};


/// Vertex data is interleaved for better performance. Check Apple docs.
struct vertexDataTextured
{
    vec3		position;
    vec3		normal;
    texCoord	uv;
};
typedef struct vertexDataTextured vertexDataTextured;
typedef vertexDataTextured* vertexDataTexturedPtr;

/// colored vertexDataTextured without normals
struct unlitVertexDataTextured
{
    vec3        vertex;
    vec4        color;
    texCoord    uv;
};
typedef struct unlitVertexDataTextured unlitVertexDataTextured;
typedef unlitVertexDataTextured* unlitVertexDataTexturedPtr;

/// colored vertexData without normals or textures. Normal = normalize(position)
struct vertexDataColored
{
    vec3        position;
    vec3        normal;
    colorRGBA   color;
};
typedef struct vertexDataColored vertexDataColored;
typedef vertexDataColored* vertexDataColoredPtr;

// for skinned models
struct vertexDataSkinned
{
    vec3        position;
    vec3        normal;
    texCoord    uv;
    vec3        boneWeights;
    byteVec4    boneIndices;
};

// -------------------------------------------------------------
// static functions
// -------------------------------------------------------------
inline GLfloat* ToGLfloat4( const math::Vector4& v ) {
    static GLfloat glv[4] = { 0, 0, 0, 0 };
    glv[0] = v.GetX() ;
    glv[1] = v.GetY() ;
    glv[2] = v.GetZ() ;
    glv[3] = v.GetW() ;
    return glv ;
}

inline const GLfloat* ToGLMatrix( const math::Matrix4& m ) {
    return static_cast<const GLfloat*>(m.GetAsArray());
}
	
inline const GLfloat* ToGLMatrix( const math::Matrix3& m ) {
    return static_cast<const GLfloat*>(m.GetAsArray());
}

GFX_NS_END


#endif // GFX_GL_MATH_H_