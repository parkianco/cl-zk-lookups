;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause
;;;;
;;;; Unified lookup verification

(in-package :cl-zk-lookups)

;;; ============================================================================
;;; Error Conditions
;;; ============================================================================

(define-condition lookup-error (error)
  ((reason :initarg :reason :reader lookup-error-reason))
  (:report (lambda (c s)
             (format s "Lookup verification failed: ~a"
                     (lookup-error-reason c)))))

;;; ============================================================================
;;; Unified Verification
;;; ============================================================================

(defun verify-lookup (proof table witness-commitment &key (type :auto))
  "Verify lookup proof of given type.
   TYPE: :plookup, :logup, :cq, or :auto (detect from proof type)."
  (let ((actual-type (if (eq type :auto)
                         (cond
                           ((plookup-proof-p proof) :plookup)
                           ((logup-proof-p proof) :logup)
                           ((cq-proof-p proof) :cq)
                           (t (error 'lookup-error :reason "Unknown proof type")))
                         type)))
    (handler-case
        (ecase actual-type
          (:plookup (plookup-verify proof table witness-commitment))
          (:logup (logup-verify proof table witness-commitment))
          (:cq (cq-verify proof table witness-commitment)))
      (error (e)
        (error 'lookup-error :reason (format nil "~a" e))))))

;;; ============================================================================
;;; Batch Verification
;;; ============================================================================

(defun batch-verify-lookups (proofs-and-tables)
  "Verify multiple lookup proofs in batch.
   PROOFS-AND-TABLES: list of (proof table witness-commitment) tuples."
  (let ((results nil))
    (dolist (entry proofs-and-tables)
      (destructuring-bind (proof table witness-commit) entry
        (push (handler-case
                  (progn (verify-lookup proof table witness-commit) t)
                (lookup-error () nil))
              results)))
    (every #'identity (nreverse results))))

;;; ============================================================================
;;; Lookup Argument Selection
;;; ============================================================================

(defun choose-lookup-type (table-size witness-size)
  "Suggest optimal lookup argument type based on sizes.
   Returns :plookup, :logup, or :cq."
  (cond
    ;; Small tables: plookup is simple and efficient
    ((< table-size 256) :plookup)
    ;; Large tables with sparse lookups: LogUp
    ((< witness-size (* table-size 0.1)) :logup)
    ;; Large tables with dense lookups: CQ
    (t :cq)))

;;; ============================================================================
;;; Proof Size Estimation
;;; ============================================================================

(defun estimate-proof-size (type table-size witness-size)
  "Estimate proof size in field elements."
  (declare (ignore witness-size))
  (ecase type
    (:plookup
     ;; Sorted vector commitment + grand product + opening
     (+ 1 1 3))
    (:logup
     ;; Accumulator + inverse sums + final
     (+ 1 table-size 1))
    (:cq
     ;; M commitment + H commitment + quotient evals
     (+ 1 1 table-size))))
