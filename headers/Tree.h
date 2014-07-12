//
//  Tree.h
//
//  Created by David Gavilan on 7/10/14.
//  Copyright (C) 2010-2014 David Gavilan Ruiz. MIT License.
//

#ifndef CORE_TREE_H_
#define CORE_TREE_H_

#include <stddef.h>
#include "core_def.h"

CORE_NS_BEGIN

template <class T>
struct TreeNode {
    uint32_t    parentIndex;
    T           node;
};

CORE_NS_END

#endif // CORE_TREE_H_
