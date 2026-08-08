(in-package #:cl-stack-icu)

;;; Extra uchar / Normalizer2 / BreakIterator / UnicodeSet / foldCase / relative date.

;;; --- uchar extras -------------------------------------------------------------

(defcfun-icu ("u_charName" u-char-name) :int32
  (code u-char32)
  (name-choice :int)
  (buffer :pointer)
  (buffer-length :int32)
  (p-error-code :pointer))

(defcfun-icu ("u_charFromName" u-char-from-name) u-char32
  (name-choice :int)
  (name :string)
  (p-error-code :pointer))

(defcfun-icu ("u_getNumericValue" u-get-numeric-value) :double
  (c u-char32))

(defcfun-icu ("u_digit" u-digit) :int32
  (ch u-char32)
  (radix :int8))

(defcfun-icu ("u_charMirror" u-char-mirror) u-char32
  (c u-char32))

(defcfun-icu ("u_charAge" u-char-age) :void
  (c u-char32)
  (version-array :pointer))

(defcfun-icu ("u_getPropertyValueName" u-get-property-value-name) :string
  (property :int)
  (value :int32)
  (name-choice :int))

(defcfun-icu ("u_strFoldCase" u-str-fold-case) :int32
  (dest :pointer)
  (dest-capacity :int32)
  (src :pointer)
  (src-length :int32)
  (options :uint32)
  (p-error-code :pointer))

;;; --- Normalizer2 extras -------------------------------------------------------

(defcfun-icu ("unorm2_isNormalized" unorm2-is-normalized) u-bool
  (norm2 :pointer)
  (src :pointer)
  (length :int32)
  (p-error-code :pointer))

(defcfun-icu ("unorm2_quickCheck" unorm2-quick-check) :int
  (norm2 :pointer)
  (src :pointer)
  (length :int32)
  (p-error-code :pointer))

(defcfun-icu ("unorm2_hasBoundaryBefore" unorm2-has-boundary-before) u-bool
  (norm2 :pointer)
  (c u-char32))

(defcfun-icu ("unorm2_hasBoundaryAfter" unorm2-has-boundary-after) u-bool
  (norm2 :pointer)
  (c u-char32))

(defcfun-icu ("unorm2_getDecomposition" unorm2-get-decomposition) :int32
  (norm2 :pointer)
  (c u-char32)
  (decomposition :pointer)
  (capacity :int32)
  (p-error-code :pointer))

;;; --- BreakIterator extras -----------------------------------------------------

(defcfun-icu ("ubrk_last" ubrk-last) :int32
  (bi :pointer))

(defcfun-icu ("ubrk_previous" ubrk-previous) :int32
  (bi :pointer))

(defcfun-icu ("ubrk_current" ubrk-current) :int32
  (bi :pointer))

(defcfun-icu ("ubrk_following" ubrk-following) :int32
  (bi :pointer)
  (offset :int32))

(defcfun-icu ("ubrk_preceding" ubrk-preceding) :int32
  (bi :pointer)
  (offset :int32))

(defcfun-icu ("ubrk_isBoundary" ubrk-is-boundary) u-bool
  (bi :pointer)
  (offset :int32))

;;; --- UnicodeSet (uset) --------------------------------------------------------

(defcfun-icu ("uset_openEmpty" uset-open-empty) :pointer)

(defcfun-icu ("uset_open" uset-open) :pointer
  (start u-char32)
  (end u-char32))

(defcfun-icu ("uset_openPattern" uset-open-pattern) :pointer
  (pattern :pointer)
  (pattern-length :int32)
  (status :pointer))

(defcfun-icu ("uset_close" uset-close) :void
  (set :pointer))

(defcfun-icu ("uset_freeze" uset-freeze) :void
  (set :pointer))

(defcfun-icu ("uset_isFrozen" uset-is-frozen) u-bool
  (set :pointer))

(defcfun-icu ("uset_add" uset-add) :void
  (set :pointer)
  (c u-char32))

(defcfun-icu ("uset_remove" uset-remove) :void
  (set :pointer)
  (c u-char32))

(defcfun-icu ("uset_addString" uset-add-string) :void
  (set :pointer)
  (str :pointer)
  (str-len :int32))

(defcfun-icu ("uset_removeString" uset-remove-string) :void
  (set :pointer)
  (str :pointer)
  (str-len :int32))

(defcfun-icu ("uset_retainAll" uset-retain-all) :void
  (set :pointer)
  (retain :pointer))

(defcfun-icu ("uset_complement" uset-complement) :void
  (set :pointer))

(defcfun-icu ("uset_clear" uset-clear) :void
  (set :pointer))

(defcfun-icu ("uset_contains" uset-contains) u-bool
  (set :pointer)
  (c u-char32))

(defcfun-icu ("uset_containsString" uset-contains-string) u-bool
  (set :pointer)
  (str :pointer)
  (str-len :int32))

(defcfun-icu ("uset_size" uset-size) :int32
  (set :pointer))

(defcfun-icu ("uset_isEmpty" uset-is-empty) u-bool
  (set :pointer))

(defcfun-icu ("uset_span" uset-span) :int32
  (set :pointer)
  (s :pointer)
  (length :int32)
  (span-condition :int))

(defcfun-icu ("uset_spanBack" uset-span-back) :int32
  (set :pointer)
  (s :pointer)
  (length :int32)
  (span-condition :int))

(defcfun-icu ("uset_spanUTF8" uset-span-utf8) :int32
  (set :pointer)
  (s :pointer)
  (length :int32)
  (span-condition :int))

(defcfun-icu ("uset_spanBackUTF8" uset-span-back-utf8) :int32
  (set :pointer)
  (s :pointer)
  (length :int32)
  (span-condition :int))

;;; --- RelativeDateTimeFormatter ------------------------------------------------

(defcfun-icu ("ureldatefmt_open" ureldatefmt-open) :pointer
  (locale :string)
  (nf-to-adopt :pointer)
  (width :int)
  (capitalization-context :int)
  (status :pointer))

(defcfun-icu ("ureldatefmt_close" ureldatefmt-close) :void
  (reldatefmt :pointer))

(defcfun-icu ("ureldatefmt_formatNumeric" ureldatefmt-format-numeric) :int32
  (reldatefmt :pointer)
  (offset :double)
  (unit :int)
  (result :pointer)
  (result-capacity :int32)
  (status :pointer))

(defcfun-icu ("ureldatefmt_format" ureldatefmt-format) :int32
  (reldatefmt :pointer)
  (offset :double)
  (unit :int)
  (result :pointer)
  (result-capacity :int32)
  (status :pointer))

(defparameter +u-no-numeric-value+ u-no-numeric-value)

;;; UDISPCTX_CAPITALIZATION_NONE = (UDISPCTX_TYPE_CAPITALIZATION<<8)+0
(defconstant +udispctx-capitalization-none+ #x100)
