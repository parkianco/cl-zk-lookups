;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause

(defpackage :cl-zk-lookups
  (:use :cl)
  (:nicknames :zk-lookups)
  (:export
   ;; Field
   #:+field-prime+
   #:field-add
   #:field-sub
   #:field-mul
   #:field-inv
   #:field-neg

   ;; Polynomial
   #:polynomial
   #:make-polynomial
   #:poly-eval
   #:poly-add
   #:poly-mul
   #:poly-scale
   #:poly-from-roots

   ;; Table
   #:lookup-table
   #:make-lookup-table
   #:lookup-table-entries
   #:lookup-table-size
   #:table-contains-p
   #:table-index-of
   #:table-to-vector

   ;; Plookup
   #:plookup-proof
   #:make-plookup-proof
   #:plookup-prove
   #:plookup-verify
   #:plookup-sorted-vector
   #:plookup-grand-product

   ;; Logup
   #:logup-proof
   #:make-logup-proof
   #:logup-prove
   #:logup-verify
   #:logup-accumulator
   #:logup-inverse-sum

   ;; CQ (Cached Quotients)
   #:cq-table
   #:make-cq-table
   #:cq-preprocess
   #:cq-proof
   #:make-cq-proof
   #:cq-prove
   #:cq-verify

   ;; Verifier
   #:verify-lookup
   #:batch-verify-lookups
   #:lookup-error
   #:lookup-error-reason))
