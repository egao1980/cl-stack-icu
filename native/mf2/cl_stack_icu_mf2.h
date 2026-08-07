/* C ABI for ICU MessageFormat 2 (C++ tech preview).
 * Linked as libcl_stack_icu_mf2 — not MF1 (umsg). */
#ifndef CL_STACK_ICU_MF2_H
#define CL_STACK_ICU_MF2_H

#include <stdint.h>
#include "unicode/utypes.h"

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32) || defined(_WIN64)
#  ifdef CL_STACK_ICU_MF2_BUILD
#    define CL_STACK_ICU_MF2_API __declspec(dllexport)
#  else
#    define CL_STACK_ICU_MF2_API __declspec(dllimport)
#  endif
#else
#  define CL_STACK_ICU_MF2_API __attribute__((visibility("default")))
#endif

typedef struct ClStackIcuMf2 ClStackIcuMf2;
typedef struct ClStackIcuMf2Args ClStackIcuMf2Args;

/* locale_bcp47: BCP 47 or ICU locale id (NUL-terminated). pattern_utf8: MF2 syntax. */
CL_STACK_ICU_MF2_API ClStackIcuMf2 *
cl_stack_icu_mf2_open(const char *locale_bcp47,
                      const char *pattern_utf8,
                      int32_t pattern_len,
                      UErrorCode *err);

CL_STACK_ICU_MF2_API void
cl_stack_icu_mf2_close(ClStackIcuMf2 *fmt);

CL_STACK_ICU_MF2_API ClStackIcuMf2Args *
cl_stack_icu_mf2_args_open(void);

CL_STACK_ICU_MF2_API void
cl_stack_icu_mf2_args_close(ClStackIcuMf2Args *args);

CL_STACK_ICU_MF2_API void
cl_stack_icu_mf2_args_set_string(ClStackIcuMf2Args *args,
                                 const char *name,
                                 const char *utf8,
                                 int32_t len,
                                 UErrorCode *err);

CL_STACK_ICU_MF2_API void
cl_stack_icu_mf2_args_set_double(ClStackIcuMf2Args *args,
                                 const char *name,
                                 double value,
                                 UErrorCode *err);

CL_STACK_ICU_MF2_API void
cl_stack_icu_mf2_args_set_int64(ClStackIcuMf2Args *args,
                                const char *name,
                                int64_t value,
                                UErrorCode *err);

/* UTF-8 into dest; returns length excluding NUL (or needed capacity on overflow). */
CL_STACK_ICU_MF2_API int32_t
cl_stack_icu_mf2_format(ClStackIcuMf2 *fmt,
                        const ClStackIcuMf2Args *args,
                        char *dest,
                        int32_t dest_capacity,
                        UErrorCode *err);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* CL_STACK_ICU_MF2_H */
