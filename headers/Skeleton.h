//
//  Skeleton.h
//
//  Created by David Gavilan on 7/7/14.
//  Copyright (C) 2014 David Gavilan Ruiz. MIT License.
//

#ifndef GFX_SKELETON_H_
#define GFX_SKELETON_H_

#include "gfx/gfx_def.h"
#include "math/Matrix.h"
#include "core/Tree.h"

GFX_NS_BEGIN

typedef struct core::TreeNode<math::Matrix4> JointTransformTree;

struct MatrixAnimData {
    const uint16_t          m_numKeyframes;
    const float*            m_keyframesMs;
    const math::Matrix4*    m_animationMatrices;
};

/**
 *  List of transform matrices per keyframe
 */
class SkeletonAnimation {
public:
    SkeletonAnimation(const uint16_t numBones);
    ~SkeletonAnimation();
    
    const math::Matrix4 GetDefaultPoseMatrix(const uint16_t jointIndex) const;
    const math::Matrix4 GetBlendedJointMatrix(uint16_t jointIndex) const;

    
    inline void SetArmature(const JointTransformTree* source);
    inline void SetArmatureTransformPtr(const math::Matrix4* source);
    inline void SetJointToSkeletonIndices(const uint16_t* source);
    inline void SetMatrixAnimData(const MatrixAnimData* source);
    
    void Update(float time_ms);
    
private:
    const math::Matrix4 GetBlendedBone(uint16_t boneIndex) const;
    
private:
    const uint16_t              m_numBones;
    const uint16_t*             m_jointToSkeletonIndices;
    const JointTransformTree*   m_jointTransformTree;
    const MatrixAnimData*       m_matrixAnimData;
    const math::Matrix4*        m_armatureTransformPtr;
    uint16_t*                   m_arrayCurrentKeyframe;
    float*                      m_arrayElapsedTimeMs;
    float*                      m_arrayBlendValue;
};

// ============================================================
// inline functions
// ---------------------------------------------------------
// just copy the pointer in most of these because the source data is static
// (otherwise, we'd need a memcpy)

inline void SkeletonAnimation::SetArmature(const JointTransformTree* source) {
    m_jointTransformTree = source;
}
inline void SkeletonAnimation::SetArmatureTransformPtr(const math::Matrix4* source) {
    m_armatureTransformPtr = source;
}
inline void SkeletonAnimation::SetJointToSkeletonIndices(const uint16_t* source) {
    m_jointToSkeletonIndices = source;
}
inline void SkeletonAnimation::SetMatrixAnimData(const vd::gfx::MatrixAnimData *source) {
    m_matrixAnimData = source;
}

GFX_NS_END


#endif // GFX_SKELETON_H_
