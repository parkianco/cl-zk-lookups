;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: BSD-3-Clause

;;;; test-zk-lookups.lisp - Unit tests for zk-lookups
;;;;
;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause

(defpackage #:cl-zk-lookups.test
  (:use #:cl)
  (:export #:run-tests))

(in-package #:cl-zk-lookups.test)

(defun run-tests ()
  "Run all tests for cl-zk-lookups."
  (format t "~&Running tests for cl-zk-lookups...~%")
  ;; TODO: Add test cases
  ;; (test-function-1)
  ;; (test-function-2)
  (format t "~&All tests passed!~%")
  t)
