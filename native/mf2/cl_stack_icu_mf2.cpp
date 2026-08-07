/* ICU MessageFormat 2 C++ → C shim for cl-stack-icu.
 * MessageFormatter is move-assignable but not move-constructible; we store
 * pattern+locale and build a formatter per format() call. */
#define CL_STACK_ICU_MF2_BUILD 1

#include "cl_stack_icu_mf2.h"

#include <map>
#include <new>
#include <string>
#include <utility>

#include "unicode/locid.h"
#include "unicode/messageformat2.h"
#include "unicode/messageformat2_arguments.h"
#include "unicode/messageformat2_formattable.h"
#include "unicode/parseerr.h"
#include "unicode/unistr.h"

using icu::Locale;
using icu::UnicodeString;
using icu::message2::Formattable;
using icu::message2::MessageArguments;
using icu::message2::MessageFormatter;

struct ClStackIcuMf2 {
  Locale locale;
  UnicodeString pattern;
};

struct ClStackIcuMf2Args {
  std::map<UnicodeString, Formattable> map;
};

static UnicodeString utf8_to_u(const char *utf8, int32_t len, UErrorCode *err) {
  if (U_FAILURE(*err) || utf8 == nullptr) {
    if (U_SUCCESS(*err)) {
      *err = U_ILLEGAL_ARGUMENT_ERROR;
    }
    return UnicodeString();
  }
  if (len < 0) {
    return UnicodeString::fromUTF8(utf8);
  }
  return UnicodeString::fromUTF8(icu::StringPiece(utf8, len));
}

static MessageFormatter build_formatter(const ClStackIcuMf2 *fmt, UErrorCode *err) {
  MessageFormatter::Builder builder(*err);
  if (U_FAILURE(*err)) {
    /* builder.build still needed for return type — use empty pattern path */
  }
  builder.setLocale(fmt->locale);
  UParseError pe{};
  builder.setPattern(fmt->pattern, pe, *err);
  return builder.build(*err);
}

extern "C" ClStackIcuMf2 *
cl_stack_icu_mf2_open(const char *locale_bcp47,
                      const char *pattern_utf8,
                      int32_t pattern_len,
                      UErrorCode *err) {
  if (err == nullptr) {
    return nullptr;
  }
  if (U_FAILURE(*err) || pattern_utf8 == nullptr) {
    if (U_SUCCESS(*err)) {
      *err = U_ILLEGAL_ARGUMENT_ERROR;
    }
    return nullptr;
  }

  Locale loc;
  if (locale_bcp47 != nullptr && locale_bcp47[0] != '\0') {
    loc = Locale::forLanguageTag(locale_bcp47, *err);
    if (U_FAILURE(*err)) {
      *err = U_ZERO_ERROR;
      loc = Locale(locale_bcp47);
    }
  }

  UnicodeString pattern = utf8_to_u(pattern_utf8, pattern_len, err);
  if (U_FAILURE(*err)) {
    return nullptr;
  }

  auto *out = new (std::nothrow) ClStackIcuMf2{std::move(loc), std::move(pattern)};
  if (out == nullptr) {
    *err = U_MEMORY_ALLOCATION_ERROR;
    return nullptr;
  }

  /* Validate pattern once at open. */
  MessageFormatter probe = build_formatter(out, err);
  (void)probe;
  if (U_FAILURE(*err)) {
    delete out;
    return nullptr;
  }
  return out;
}

extern "C" void
cl_stack_icu_mf2_close(ClStackIcuMf2 *fmt) {
  delete fmt;
}

extern "C" ClStackIcuMf2Args *
cl_stack_icu_mf2_args_open(void) {
  return new (std::nothrow) ClStackIcuMf2Args();
}

extern "C" void
cl_stack_icu_mf2_args_close(ClStackIcuMf2Args *args) {
  delete args;
}

extern "C" void
cl_stack_icu_mf2_args_set_string(ClStackIcuMf2Args *args,
                                 const char *name,
                                 const char *utf8,
                                 int32_t len,
                                 UErrorCode *err) {
  if (err == nullptr || U_FAILURE(*err) || args == nullptr || name == nullptr) {
    if (err != nullptr && U_SUCCESS(*err)) {
      *err = U_ILLEGAL_ARGUMENT_ERROR;
    }
    return;
  }
  UnicodeString key = UnicodeString::fromUTF8(name);
  UnicodeString val = utf8_to_u(utf8, len, err);
  if (U_FAILURE(*err)) {
    return;
  }
  args->map[key] = Formattable(val);
}

extern "C" void
cl_stack_icu_mf2_args_set_double(ClStackIcuMf2Args *args,
                                 const char *name,
                                 double value,
                                 UErrorCode *err) {
  if (err == nullptr || U_FAILURE(*err) || args == nullptr || name == nullptr) {
    if (err != nullptr && U_SUCCESS(*err)) {
      *err = U_ILLEGAL_ARGUMENT_ERROR;
    }
    return;
  }
  args->map[UnicodeString::fromUTF8(name)] = Formattable(value);
}

extern "C" void
cl_stack_icu_mf2_args_set_int64(ClStackIcuMf2Args *args,
                                const char *name,
                                int64_t value,
                                UErrorCode *err) {
  if (err == nullptr || U_FAILURE(*err) || args == nullptr || name == nullptr) {
    if (err != nullptr && U_SUCCESS(*err)) {
      *err = U_ILLEGAL_ARGUMENT_ERROR;
    }
    return;
  }
  args->map[UnicodeString::fromUTF8(name)] = Formattable(value);
}

extern "C" int32_t
cl_stack_icu_mf2_format(ClStackIcuMf2 *fmt,
                        const ClStackIcuMf2Args *args,
                        char *dest,
                        int32_t dest_capacity,
                        UErrorCode *err) {
  if (err == nullptr) {
    return -1;
  }
  if (U_FAILURE(*err) || fmt == nullptr) {
    if (U_SUCCESS(*err)) {
      *err = U_ILLEGAL_ARGUMENT_ERROR;
    }
    return -1;
  }

  MessageFormatter formatter = build_formatter(fmt, err);
  if (U_FAILURE(*err)) {
    return -1;
  }

  const ClStackIcuMf2Args empty{};
  const ClStackIcuMf2Args *use = (args != nullptr) ? args : &empty;
  MessageArguments marg(use->map, *err);
  if (U_FAILURE(*err)) {
    return -1;
  }

  UnicodeString result = formatter.formatToString(marg, *err);
  if (U_FAILURE(*err)) {
    return -1;
  }

  std::string utf8;
  result.toUTF8String(utf8);
  const int32_t need = static_cast<int32_t>(utf8.size());
  if (dest == nullptr || dest_capacity <= need) {
    *err = U_BUFFER_OVERFLOW_ERROR;
    return need;
  }
  utf8.copy(dest, static_cast<size_t>(need));
  dest[need] = '\0';
  return need;
}
