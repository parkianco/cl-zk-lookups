;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause

(asdf:defsystem #::cl-zk-lookups
  :description "Zero-knowledge lookup arguments (plookup, logup, cq)"
  :author "Parkian Company LLC"
  :license "BSD-3-Clause"
  :version "0.1.0"
  :depends-on ()
  :serial t
  :components
  ((:file "package")
   (:module "src"
    :components
    ((:file "field")
     (:file "polynomial")
     (:file "table")
     (:file "plookup")
     (:file "logup")
     (:file "cq")
     (:file "verifier")))))

(asdf:defsystem #:cl-zk-lookups/test
  :description "Tests for cl-zk-lookups"
  :depends-on (#:cl-zk-lookups)
  :serial t
  :components ((:module "test"
                :components ((:file "test-zk-lookups"))))
  :perform (asdf:test-op (o c)
             (let ((result (uiop:symbol-call :cl-zk-lookups.test :run-tests)))
               (unless result
                 (error "Tests failed")))))
