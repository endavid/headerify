/*
 *  Matrix.h
 *
 *  Created by David Gavilan on 10/12/09.
 *  Copyright (C) 2010-2014 David Gavilan Ruiz. MIT License.
 *
 */
#ifndef MATH_MATRIX_H_
#define MATH_MATRIX_H_

#include "Vector.h"
#include "math_def.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
// vDSP functions
#include <Accelerate/Accelerate.h>
#endif

// http://www.parashift.com/c++-faq-lite/operator-overloading.html#faq-13.10

MATH_NS_BEGIN

class Matrix3 {
public:
    static inline const Matrix3 Identity();
public:
    Matrix3(const float value)  {
        m_col[0] = Vector3(value);
        m_col[1] = Vector3(value);
        m_col[2] = Vector3(value);
    }
    
    inline const Vector3& GetCol(uint32_t col) const {
        return m_col[col];
    }
    inline void SetCol(uint32_t col, const Vector3& v) {
        m_col[col] = v ;
    }
    inline void SetRow(uint32_t row, const Vector3& v) {
        m_col[0](row) = v.GetX();
        m_col[1](row) = v.GetY();
        m_col[2](row) = v.GetZ();
    }
    /// m(row,col) = f;
    inline float& operator() (uint32_t row, uint32_t col) {
        return m_col[col](row);
    }
    /// float f = m(row,col);
    inline float  operator() (uint32_t row, uint32_t col) const {
        return m_col[col](row);
    }
    /// operators
    inline Matrix3 operator*(const Matrix3& rhs) const;
    inline const float* GetAsArray() const;
    inline float* GetAsArray();

    inline Matrix3 Transpose() const {
        Matrix3 m(0);
        m.SetRow(0, GetCol(0));
        m.SetRow(1, GetCol(1));
        m.SetRow(2, GetCol(2));
        return m;
    }
    
private:
    Vector3	m_col[3];
};


class Matrix4 {
public:
    static inline const Matrix4 Identity();
public:
    Matrix4(const float value)  {
        m_col[0] = Vector4(value);
        m_col[1] = Vector4(value);
        m_col[2] = Vector4(value);
        m_col[3] = Vector4(value);
    }
    
    /**
     *  @param isRowMajor, read elements in row order. The default
     *          is true, more readable & convenient to read Collada matrices.
     */
    Matrix4(float a0, float a1, float a2, float a3,
            float a4, float a5, float a6, float a7,
            float a8, float a9, float a10, float a11,
            float a12, float a13, float a14, float a15,
            bool isRowMajor = true) {
        if (isRowMajor) {
            m_col[0] = Vector4(a0, a4, a8, a12);
            m_col[1] = Vector4(a1, a5, a9, a13);
            m_col[2] = Vector4(a2, a6, a10, a14);
            m_col[3] = Vector4(a3, a7, a11, a15);
        } else {
            m_col[0] = Vector4(a0, a1, a2, a3);
            m_col[1] = Vector4(a4, a5, a6, a7);
            m_col[2] = Vector4(a8, a9, a10, a11);
            m_col[3] = Vector4(a12, a13, a14, a15);
        }
    }
    
    inline const Vector4& GetCol(uint32_t col) const {
        return m_col[col];
    }
    inline void SetCol(uint32_t col, const Vector4& v) {
        m_col[col] = v ;
    }
    inline void SetRow(uint32_t row, const Vector4& v) {
        m_col[0](row) = v.GetX();
        m_col[1](row) = v.GetY();
        m_col[2](row) = v.GetZ();
        m_col[3](row) = v.GetW();
    }
    /// m(row,col) = f;
    inline float& operator() (uint32_t row, uint32_t col) {
        return m_col[col](row);
    }
    /// float f = m(row,col);
    inline float  operator() (uint32_t row, uint32_t col) const {
        return m_col[col](row);
    }
    /// operators
    inline Matrix4 operator*(const Matrix4& rhs) const;
    inline const float* GetAsArray() const;
    inline float* GetAsArray();
    inline Matrix4& operator+=(const Matrix4& rhs) {
        m_col[0] += rhs.GetCol(0);
        m_col[1] += rhs.GetCol(1);
        m_col[2] += rhs.GetCol(2);
        m_col[3] += rhs.GetCol(3);
        return *this;
    }
    inline Matrix4 operator+(const Matrix4& rhs) const {
        return Matrix4(*this) += rhs;
    }
    inline Matrix4& operator*=(const float rhs) {
        m_col[0] *= rhs;
        m_col[1] *= rhs;
        m_col[2] *= rhs;
        m_col[3] *= rhs;
        return *this;
    }
    inline Matrix4 operator*(const float rhs) const {
        return Matrix4(*this) *= rhs ;
    }
    inline Matrix4 Transpose() const {
        Matrix4 m(0);
        m.SetRow(0, GetCol(0));
        m.SetRow(1, GetCol(1));
        m.SetRow(2, GetCol(2));
        m.SetRow(3, GetCol(3));
        return m;
    }

    // rather don't use. Define View matrices using Transform.
    //static Matrix4 LookAt(const Vector3& position,const Vector3& target,const Vector3& up);

    
    // -----------------------------------------------------------------------
    // Projection Matrices
    //  Notice that the only way to represent projections is through matrices
    //  For other 3D transformations, better use the Transform class.
    // -----------------------------------------------------------------------
    static Matrix4 CreateFrustum(float left,float right,float bottom,float top,float near,float far);
    static Matrix4 CreateOrtho(float left,float right,float bottom,float top, float near,float far);
    static Matrix4 Perspective(float fov,float near,float far,float aspectRatio);

    
private:
    Vector4	m_col[4];
};


// ================================================================
// inline functions

inline const Matrix3 Matrix3::Identity() {
    Matrix3 m(0);
    m.m_col[0].SetX(1.f);
    m.m_col[1].SetY(1.f);
    m.m_col[2].SetZ(1.f);
    return m;
}

/// Matrix multiplication
inline Matrix3 Matrix3::operator*(const Matrix3& rhs) const {
    Matrix3 m(0);
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    vDSP_mmul(const_cast<float*>(rhs.GetAsArray()), 1, const_cast<float*>(GetAsArray()), 1, m.GetAsArray(), 1, 3, 3, 3);
#else
    m(0,0) = (*this)(0,0)*rhs(0,0)+(*this)(0,1)*rhs(1,0)+(*this)(0,2)*rhs(2,0);
    m(0,1) = (*this)(0,0)*rhs(0,1)+(*this)(0,1)*rhs(1,1)+(*this)(0,2)*rhs(2,1);
    m(0,2) = (*this)(0,0)*rhs(0,2)+(*this)(0,1)*rhs(1,2)+(*this)(0,2)*rhs(2,2);
    m(1,0) = (*this)(1,0)*rhs(0,0)+(*this)(1,1)*rhs(1,0)+(*this)(1,2)*rhs(2,0);
    m(1,1) = (*this)(1,0)*rhs(0,1)+(*this)(1,1)*rhs(1,1)+(*this)(1,2)*rhs(2,1);
    m(1,2) = (*this)(1,0)*rhs(0,2)+(*this)(1,1)*rhs(1,2)+(*this)(1,2)*rhs(2,2);
    m(2,0) = (*this)(2,0)*rhs(0,0)+(*this)(2,1)*rhs(1,0)+(*this)(2,2)*rhs(2,0);
    m(2,1) = (*this)(2,0)*rhs(0,1)+(*this)(2,1)*rhs(1,1)+(*this)(2,2)*rhs(2,1);
    m(2,2) = (*this)(2,0)*rhs(0,2)+(*this)(2,1)*rhs(1,2)+(*this)(2,2)*rhs(2,2);
#endif
    
    return m;
}


const float* Matrix3::GetAsArray() const {
    return m_col[0].GetAsArray();
}
float* Matrix3::GetAsArray() {
    return m_col[0].GetAsArray();
}

// --------------------------------------------------

inline const Matrix4 Matrix4::Identity() {
    Matrix4 m(0);
    m.m_col[0].SetX(1.f);
    m.m_col[1].SetY(1.f);
    m.m_col[2].SetZ(1.f);
    m.m_col[3].SetW(1.f);
    return m;
}

/// Matrix multiplication
inline Matrix4 Matrix4::operator*(const Matrix4& rhs) const {
    Matrix4 m(0);
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    vDSP_mmul(const_cast<float*>(rhs.GetAsArray()), 1, const_cast<float*>(GetAsArray()), 1, m.GetAsArray(), 1, 4, 4, 4);
#else
    m(0,0) = (*this)(0,0)*rhs(0,0)+(*this)(0,1)*rhs(1,0)+(*this)(0,2)*rhs(2,0)+(*this)(0,3)*rhs(3,0);
    m(0,1) = (*this)(0,0)*rhs(0,1)+(*this)(0,1)*rhs(1,1)+(*this)(0,2)*rhs(2,1)+(*this)(0,3)*rhs(3,1);
    m(0,2) = (*this)(0,0)*rhs(0,2)+(*this)(0,1)*rhs(1,2)+(*this)(0,2)*rhs(2,2)+(*this)(0,3)*rhs(3,2);
    m(0,3) = (*this)(0,0)*rhs(0,3)+(*this)(0,1)*rhs(1,3)+(*this)(0,2)*rhs(2,3)+(*this)(0,3)*rhs(3,3);
    m(1,0) = (*this)(1,0)*rhs(0,0)+(*this)(1,1)*rhs(1,0)+(*this)(1,2)*rhs(2,0)+(*this)(1,3)*rhs(3,0);
    m(1,1) = (*this)(1,0)*rhs(0,1)+(*this)(1,1)*rhs(1,1)+(*this)(1,2)*rhs(2,1)+(*this)(1,3)*rhs(3,1);
    m(1,2) = (*this)(1,0)*rhs(0,2)+(*this)(1,1)*rhs(1,2)+(*this)(1,2)*rhs(2,2)+(*this)(1,3)*rhs(3,2);
    m(1,3) = (*this)(1,0)*rhs(0,3)+(*this)(1,1)*rhs(1,3)+(*this)(1,2)*rhs(2,3)+(*this)(1,3)*rhs(3,3);
    m(2,0) = (*this)(2,0)*rhs(0,0)+(*this)(2,1)*rhs(1,0)+(*this)(2,2)*rhs(2,0)+(*this)(2,3)*rhs(3,0);
    m(2,1) = (*this)(2,0)*rhs(0,1)+(*this)(2,1)*rhs(1,1)+(*this)(2,2)*rhs(2,1)+(*this)(2,3)*rhs(3,1);
    m(2,2) = (*this)(2,0)*rhs(0,2)+(*this)(2,1)*rhs(1,2)+(*this)(2,2)*rhs(2,2)+(*this)(2,3)*rhs(3,2);
    m(2,3) = (*this)(2,0)*rhs(0,3)+(*this)(2,1)*rhs(1,3)+(*this)(2,2)*rhs(2,3)+(*this)(2,3)*rhs(3,3);
    m(3,0) = (*this)(3,0)*rhs(0,0)+(*this)(3,1)*rhs(1,0)+(*this)(3,2)*rhs(2,0)+(*this)(3,3)*rhs(3,0);
    m(3,1) = (*this)(3,0)*rhs(0,1)+(*this)(3,1)*rhs(1,1)+(*this)(3,2)*rhs(2,1)+(*this)(3,3)*rhs(3,1);
    m(3,2) = (*this)(3,0)*rhs(0,2)+(*this)(3,1)*rhs(1,2)+(*this)(3,2)*rhs(2,2)+(*this)(3,3)*rhs(3,2);
    m(3,3) = (*this)(3,0)*rhs(0,3)+(*this)(3,1)*rhs(1,3)+(*this)(3,2)*rhs(2,3)+(*this)(3,3)*rhs(3,3);
#endif
    
    return m;
}


const float* Matrix4::GetAsArray() const {
    return m_col[0].GetAsArray();
}
float* Matrix4::GetAsArray() {
    return m_col[0].GetAsArray();
}



MATH_NS_END

#endif // MATH_MATRIX_H_