//
//  FontDef.h
//
//  Created by David Gavilan on 1/27/13.
//
//

#ifndef UI_FONT_DEF_H_
#define UI_FONT_DEF_H_

#include "ui/ui_def.h"
#include "math/Vector.h"

UI_NS_BEGIN

/// Unicode character location in the bitmap font
struct UniChar {
    int key;   ///< ID, char code
    uint32_t x;
    uint32_t y;
    uint32_t width;
    uint32_t height;
    int xoffset;
    int yoffset;
    int xadvance;
    //int page;
    //int chnl;
};
//char id=33 x=396 y=1 width=14 height=36 xoffset=0 yoffset=-1 xadvance=14 page=0 chnl=0

/// Font descriptor of the bitmap font
struct FontDesc {
    const char*     file;
    const char*     face;
    const char*     charset;
    uint32_t        size;
    uint32_t        stretchH;
    bool            bold;
    bool            italic;
    bool            unicode;
    bool            smooth;
    bool            aa;     ///< Antialiasing
    math::Vector4   padding;
    math::Vector2   spacing;
    uint32_t        lineHeight;
    uint32_t        base;
    uint32_t        scaleW;
    uint32_t        scaleH;
    uint32_t        charCount;
    const UniChar*  chars;
    // uint32_t pages;
};

// info face="Hobo Std" size=36 bold=0 italic=0 charset="" unicode=0 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=0,0
//common lineHeight=38 base=34 scaleW=512 scaleH=256 pages=1 packed=0
//page id=0 file="latin_hobo-hd.png"
//chars count=105
UI_NS_END

#endif // UI_FONT_DEF_H_
