(defpackage #:cl-stack-icu
  (:use #:cl #:cffi)
  (:export #:icu-version-string
           #:icu-error
           #:icu-error-code
           #:icu-error-message
           #:check-icu
           #:u-success-p
           #:u-failure-p
           ;; unicode
           #:u-get-version
           #:u-version-to-string
           #:u-error-name
           #:u-strlen
           #:u-str-to-utf8
           #:u-str-from-utf8
           #:u-chars-to-lisp
           #:u-has-binary-property
           #:u-get-int-property-value
           #:u-char-type
           #:u-tolower
           #:u-toupper
           #:u-fold-case
           #:unorm2-get-nfc-instance
           #:unorm2-get-nfd-instance
           #:unorm2-get-nfkc-instance
           #:unorm2-get-nfkd-instance
           #:unorm2-get-nfkc-casefold-instance
           #:unorm2-normalize
           #:ubrk-open
           #:ubrk-close
           #:ubrk-first
           #:ubrk-next
           #:ubrk-last
           #:ubrk-previous
           #:ubrk-current
           #:ubrk-following
           #:ubrk-preceding
           #:ubrk-is-boundary
           #:ubrk-set-text
           #:u-char-name
           #:u-char-from-name
           #:u-get-numeric-value
           #:u-digit
           #:u-char-mirror
           #:u-char-age
           #:u-get-property-value-name
           #:u-str-fold-case
           #:unorm2-is-normalized
           #:unorm2-quick-check
           #:unorm2-has-boundary-before
           #:unorm2-has-boundary-after
           #:unorm2-get-decomposition
           #:uset-open-empty
           #:uset-open
           #:uset-open-pattern
           #:uset-close
           #:uset-freeze
           #:uset-is-frozen
           #:uset-add
           #:uset-remove
           #:uset-add-string
           #:uset-remove-string
           #:uset-retain-all
           #:uset-complement
           #:uset-clear
           #:uset-contains
           #:uset-contains-string
           #:uset-size
           #:uset-is-empty
           #:uset-span
           #:uset-span-back
           #:uset-span-utf8
           #:uset-span-back-utf8
           #:ureldatefmt-open
           #:ureldatefmt-close
           #:ureldatefmt-format-numeric
           #:ureldatefmt-format
           #:+u-no-numeric-value+
           #:+udispctx-capitalization-none+
           #:u-char-name-choice
           #:u-property-name-choice
           #:u-set-span-condition
           #:u-relative-date-time-unit
           #:u-date-relative-date-time-formatter-style
           #:u-no-numeric-value
           #:uidna-open-uts46
           #:uidna-close
           #:uidna-name-to-ascii
           #:uidna-name-to-unicode
           #:uidna-label-to-ascii
           #:uidna-label-to-unicode
           #:uscript-get-script-extensions
           #:udatpg-open
           #:udatpg-close
           #:udatpg-get-best-pattern
           ;; locale / resources / case
           #:uloc-get-default
           #:uloc-set-default
           #:uloc-get-language
           #:uloc-get-script
           #:uloc-get-country
           #:uloc-get-name
           #:uloc-canonicalize
           #:uloc-for-language-tag
           #:uloc-to-language-tag
           #:uloc-count-available
           #:uloc-get-available
           #:ures-open
           #:ures-close
           #:ures-get-by-key
           #:ures-get-by-index
           #:ures-get-string
           #:ures-get-type
           #:ures-get-key
           #:ures-get-size
           #:ures-get-locale-by-type
           #:u-str-to-lower
           #:u-str-to-upper
           #:u-str-to-title
           ;; collation
           #:ucol-open
           #:ucol-close
           #:ucol-strcoll-utf8
           #:ucol-get-sort-key
           #:ucol-set-strength
           #:ucol-get-strength
           ;; number / date
           #:unum-open
           #:unum-close
           #:unum-format-double
           #:unum-format-double-currency
           #:unum-parse-double
           #:unumf-open-for-skeleton-and-locale
           #:unumf-close
           #:unumf-open-result
           #:unumf-close-result
           #:unumf-format-double
           #:unumf-format-int
           #:unumf-result-as-value
           #:ufmtval-get-string
           #:udat-open
           #:udat-close
           #:udat-format
           #:udat-parse
           ;; plurals / lists
           #:uplrules-open-for-type
           #:uplrules-close
           #:uplrules-select
           #:ulistfmt-open-for-type
           #:ulistfmt-close
           #:ulistfmt-format
           ;; MF2 shim
           #:mf2-open
           #:mf2-close
           #:mf2-args-open
           #:mf2-args-close
           #:mf2-args-set-string
           #:mf2-args-set-double
           #:mf2-args-set-int64
           #:mf2-format
           #:mf2-format-message
           #:+icu-soname-major+
           #:+u-fold-case-default+
           #:+u-fold-case-exclude-special-i+
           #:+uidna-default+
           #:+uidna-use-std3-rules+
           #:+uidna-check-bidi+
           #:+uidna-check-contextj+
           #:+uidna-check-contexto+
           #:+uidna-nontransitional-to-ascii+
           #:+uidna-nontransitional-to-unicode+
           #:*icu-loaded*
           ;; grovelled ctypes / constants / cenums (package-qualified for foreign-enum-value)
           #:u-char #:u-char32 #:u-bool
           #:u-icu-version-major-num
           #:u-icu-version-minor-num
           #:u-icu-version-patchlevel-num
           #:u-fold-case-default
           #:u-fold-case-exclude-special-i
           #:uidna-option
           #:u-error-code
           #:u-char-category
           #:u-property
           #:u-break-iterator-type
           #:u-col-attribute-value
           #:u-collation-result
           #:u-number-format-style
           #:u-date-format-style
           #:u-plural-type
           #:u-list-formatter-type
           #:u-list-formatter-width
           #:u-res-type))
(in-package #:cl-stack-icu)

;;; Must match ICU major in package :version / sonames (icudt78.dll, libicuuc.so.78, …).
(defconstant +icu-soname-major+ 78)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (when (uiop:getenv "HOMEBREW_PREFIX")
    (pushnew :homebrew *features*))
  (when (uiop:getenv "CL_STACK_ICU_INCLUDE")
    (pushnew :cl-stack-icu-include *features*)))
