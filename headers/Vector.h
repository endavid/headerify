#ifndef MATH_VECTOR_H_
#define MATH_VECTOR_H_

#include "math/math_def.h"

MATH_NS_BEGIN

struct Vector2 {
    float x;
    float y;

    Vector2(float pX, float pY)
    : x(pX), y(pY)
    {}
};

struct Vector3 {
};

struct Vector4 {
};

MATH_NS_END

