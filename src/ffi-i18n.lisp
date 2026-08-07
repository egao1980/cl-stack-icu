(in-package #:cl-stack-icu)

;;; Locale, resource bundles, collation, number/date format, plurals, lists, locale case.

;;; --- locale (uloc) ------------------------------------------------------------

(defcfun-icu ("uloc_getDefault" uloc-get-default) :string)

(defcfun-icu ("uloc_setDefault" uloc-set-default) :void
  (locale-id :string)
  (status :pointer))

(defcfun-icu ("uloc_getLanguage" uloc-get-language) :int32
  (locale-id :string)
  (language :pointer)
  (language-capacity :int32)
  (err :pointer))

(defcfun-icu ("uloc_getScript" uloc-get-script) :int32
  (locale-id :string)
  (script :pointer)
  (script-capacity :int32)
  (err :pointer))

(defcfun-icu ("uloc_getCountry" uloc-get-country) :int32
  (locale-id :string)
  (country :pointer)
  (country-capacity :int32)
  (err :pointer))

(defcfun-icu ("uloc_getName" uloc-get-name) :int32
  (locale-id :string)
  (name :pointer)
  (name-capacity :int32)
  (err :pointer))

(defcfun-icu ("uloc_canonicalize" uloc-canonicalize) :int32
  (locale-id :string)
  (name :pointer)
  (name-capacity :int32)
  (err :pointer))

(defcfun-icu ("uloc_forLanguageTag" uloc-for-language-tag) :int32
  (langtag :string)
  (locale-id :pointer)
  (locale-id-capacity :int32)
  (parsed-length :pointer)
  (err :pointer))

(defcfun-icu ("uloc_toLanguageTag" uloc-to-language-tag) :int32
  (locale-id :string)
  (langtag :pointer)
  (langtag-capacity :int32)
  (strict u-bool)
  (err :pointer))

(defcfun-icu ("uloc_countAvailable" uloc-count-available) :int32)

(defcfun-icu ("uloc_getAvailable" uloc-get-available) :string
  (n :int32))

;;; --- resource bundles (ures) --------------------------------------------------

(defcfun-icu ("ures_open" ures-open) :pointer
  (package-name :string)
  (locale :string)
  (status :pointer))

(defcfun-icu ("ures_close" ures-close) :void
  (resource-bundle :pointer))

(defcfun-icu ("ures_getByKey" ures-get-by-key) :pointer
  (resource-bundle :pointer)
  (key :string)
  (fill-in :pointer)
  (status :pointer))

(defcfun-icu ("ures_getByIndex" ures-get-by-index) :pointer
  (resource-bundle :pointer)
  (index-r :int32)
  (fill-in :pointer)
  (status :pointer))

(defcfun-icu ("ures_getString" ures-get-string) :pointer
  (resource-bundle :pointer)
  (len :pointer)
  (status :pointer))

(defcfun-icu ("ures_getType" ures-get-type) :int
  (resource-bundle :pointer))

(defcfun-icu ("ures_getKey" ures-get-key) :string
  (resource-bundle :pointer))

(defcfun-icu ("ures_getSize" ures-get-size) :int32
  (resource-bundle :pointer))

(defcfun-icu ("ures_getLocaleByType" ures-get-locale-by-type) :string
  (resource-bundle :pointer)
  (type :int)
  (status :pointer))

;;; --- locale-aware case (ustring) ----------------------------------------------

(defcfun-icu ("u_strToLower" u-str-to-lower) :int32
  (dest :pointer)
  (dest-capacity :int32)
  (src :pointer)
  (src-length :int32)
  (locale :string)
  (p-error-code :pointer))

(defcfun-icu ("u_strToUpper" u-str-to-upper) :int32
  (dest :pointer)
  (dest-capacity :int32)
  (src :pointer)
  (src-length :int32)
  (locale :string)
  (p-error-code :pointer))

(defcfun-icu ("u_strToTitle" u-str-to-title) :int32
  (dest :pointer)
  (dest-capacity :int32)
  (src :pointer)
  (src-length :int32)
  (title-iter :pointer)
  (locale :string)
  (p-error-code :pointer))

;;; --- collation (ucol) ---------------------------------------------------------

(defcfun-icu ("ucol_open" ucol-open) :pointer
  (loc :string)
  (status :pointer))

(defcfun-icu ("ucol_close" ucol-close) :void
  (coll :pointer))

(defcfun-icu ("ucol_strcollUTF8" ucol-strcoll-utf8) :int
  (coll :pointer)
  (source :pointer)
  (source-length :int32)
  (target :pointer)
  (target-length :int32)
  (status :pointer))

(defcfun-icu ("ucol_getSortKey" ucol-get-sort-key) :int32
  (coll :pointer)
  (source :pointer)
  (source-length :int32)
  (result :pointer)
  (result-length :int32))

(defcfun-icu ("ucol_setStrength" ucol-set-strength) :void
  (coll :pointer)
  (strength :int))

(defcfun-icu ("ucol_getStrength" ucol-get-strength) :int
  (coll :pointer))

(defcfun-icu ("ucol_getLocaleByType" ucol-get-locale-by-type) :string
  (coll :pointer)
  (type :int)
  (status :pointer))

;;; --- number format (unum) -----------------------------------------------------

(defcfun-icu ("unum_open" unum-open) :pointer
  (style :int)
  (pattern :pointer)
  (pattern-length :int32)
  (locale :string)
  (parse-err :pointer)
  (status :pointer))

(defcfun-icu ("unum_close" unum-close) :void
  (fmt :pointer))

(defcfun-icu ("unum_formatDouble" unum-format-double) :int32
  (fmt :pointer)
  (number :double)
  (result :pointer)
  (result-length :int32)
  (pos :pointer)
  (status :pointer))

(defcfun-icu ("unum_formatDoubleCurrency" unum-format-double-currency) :int32
  (fmt :pointer)
  (number :double)
  (currency :pointer)
  (result :pointer)
  (result-length :int32)
  (pos :pointer)
  (status :pointer))

(defcfun-icu ("unum_parseDouble" unum-parse-double) :double
  (fmt :pointer)
  (text :pointer)
  (text-length :int32)
  (parse-pos :pointer)
  (status :pointer))

(defcfun-icu ("unum_setTextAttribute" unum-set-text-attribute) :void
  (fmt :pointer)
  (tag :int)
  (new-value :pointer)
  (new-value-length :int32)
  (status :pointer))

;;; --- number formatter skeletons (unumf) ---------------------------------------

(defcfun-icu ("unumf_openForSkeletonAndLocale" unumf-open-for-skeleton-and-locale) :pointer
  (skeleton :pointer)
  (skeleton-len :int32)
  (locale :string)
  (ec :pointer))

(defcfun-icu ("unumf_close" unumf-close) :void
  (u :pointer))

(defcfun-icu ("unumf_openResult" unumf-open-result) :pointer
  (ec :pointer))

(defcfun-icu ("unumf_closeResult" unumf-close-result) :void
  (uresult :pointer))

(defcfun-icu ("unumf_formatDouble" unumf-format-double) :void
  (u :pointer)
  (value :double)
  (result :pointer)
  (ec :pointer))

(defcfun-icu ("unumf_formatInt" unumf-format-int) :void
  (u :pointer)
  (value :int64)
  (result :pointer)
  (ec :pointer))

(defcfun-icu ("ufmtval_getString" ufmtval-get-string) :pointer
  (ufmtval :pointer)
  (p-length :pointer)
  (ec :pointer))

(defcfun-icu ("unumf_resultAsValue" unumf-result-as-value) :pointer
  (uresult :pointer)
  (ec :pointer))

;;; --- date format (udat) -------------------------------------------------------

(defcfun-icu ("udat_open" udat-open) :pointer
  (time-style :int)
  (date-style :int)
  (locale :string)
  (tz-id :pointer)
  (tz-id-length :int32)
  (pattern :pointer)
  (pattern-length :int32)
  (status :pointer))

(defcfun-icu ("udat_close" udat-close) :void
  (format :pointer))

(defcfun-icu ("udat_format" udat-format) :int32
  (format :pointer)
  (date-to-format :double)
  (result :pointer)
  (result-length :int32)
  (position :pointer)
  (status :pointer))

(defcfun-icu ("udat_parse" udat-parse) :double
  (format :pointer)
  (text :pointer)
  (text-length :int32)
  (parse-pos :pointer)
  (status :pointer))

;;; --- plural rules -------------------------------------------------------------

(defcfun-icu ("uplrules_openForType" uplrules-open-for-type) :pointer
  (locale :string)
  (type :int)
  (status :pointer))

(defcfun-icu ("uplrules_close" uplrules-close) :void
  (uplrules :pointer))

(defcfun-icu ("uplrules_select" uplrules-select) :int32
  (uplrules :pointer)
  (number :double)
  (keyword :pointer)
  (capacity :int32)
  (status :pointer))

;;; --- list formatter -----------------------------------------------------------

(defcfun-icu ("ulistfmt_openForType" ulistfmt-open-for-type) :pointer
  (locale :string)
  (type :int)
  (width :int)
  (status :pointer))

(defcfun-icu ("ulistfmt_close" ulistfmt-close) :void
  (listfmt :pointer))

(defcfun-icu ("ulistfmt_format" ulistfmt-format) :int32
  (listfmt :pointer)
  (strings :pointer)
  (string-lengths :pointer)
  (string-count :int32)
  (result :pointer)
  (result-capacity :int32)
  (status :pointer))
