#ifndef __SHADOWSTACK_H__
#define __SHADOWSTACK_H__

#include "common.h"
#include "nursery.h"
#include "semispace.h"

extern int ss_used;
void ss_push(hp* ref);
void ss_pop();
void ss_mark();

#define SS_USE(ref, code) \
  ss_push(ref); code; ss_pop()

#define _ss_allocate(ret, ns, semi, s, t, prims, ptrs, mutable, o, size)     \
  do {                                                              \
    do {                                                            \
      ret = _allocate(ns, semi, t, prims, ptrs, mutable, o, size);           \
      if(ret==NULL) {                                               \
        nursery_begin(ns, semi, s);                                 \
        ss_mark(ns, semi);                                          \
        nursery_end(ns, semi, s);                                   \
        semi_scavenge_concurrent(semi, s);                          \
        if(!semi_check(semi, NURSERY_SIZE)) {                       \
          semi_scavenge(semi, s);                                   \
        }                                                           \
      }                                                             \
    } while (ret==NULL);                                            \
  } while(0)

#define ss_allocate(ret, ns, semi, s, tag, ...) _ss_allocate(ret, ns, semi, s, tag, InfoTable[tag].prims, InfoTable[tag].ptrs, InfoTable[tag].mutable, ((Object)(__VA_ARGS__)), sizeof((__VA_ARGS__)))

#endif
