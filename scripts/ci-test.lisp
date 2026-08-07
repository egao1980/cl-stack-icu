;;;; Phase 2: load checkout + run tests (natives already built / on search path).

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&UNHANDLED: ~A~%" c)
        (uiop:quit 1)))

(setf asdf:*compile-file-failure-behaviour* :warn)

(defun call-with-ci-muffles (fn)
  #+sbcl
  (handler-bind ((sb-ext:defconstant-uneql
                  (lambda (c)
                    (let ((r (find-restart 'continue c)))
                      (when r (invoke-restart r))))))
    (funcall fn))
  #-sbcl
  (funcall fn))

(call-with-ci-muffles (lambda () (asdf:load-system "cl-repository-client")))

(cl-repo:add-registry "https://ghcr.io" :namespace "egao1980/cl-systems" :priority :prepend)

(when (uiop:getenv "CI_INSTALL_DEPS_ONLY")
  (call-with-ci-muffles
   (lambda ()
     (cl-repo:ensure-system-dependencies "cl-stack-icu"
       :also-tests t
       :sources '(("cffi" :ql)
                  ("cffi-grovel" :ql)
                  ("babel" :ql)
                  ("trivial-features" :ql)
                  ("cl-unicode" :ql)
                  ("rove" :ql)))))
  (format t "~&; ci: deps-only done~%")
  (uiop:quit 0))

(call-with-ci-muffles
 (lambda ()
   (unless (asdf:find-system "cffi-grovel" nil)
     (ql:quickload "cffi-grovel" :silent t))
   (unless (asdf:find-system "rove" nil)
     (ql:quickload "rove" :silent t))
   (asdf:test-system "cl-stack-icu")))

(uiop:quit 0)
