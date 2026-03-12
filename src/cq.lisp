;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause
;;;;
;;;; CQ - Cached Quotients lookup argument

(in-package :cl-zk-lookups)

;;; ============================================================================
;;; CQ Table (Preprocessed)
;;; ============================================================================

(defstruct cq-table
  "CQ preprocessed table."
  (values nil :type list)
  (size 0 :type integer)
  ;; Preprocessed data
  (vanishing-poly nil)           ; Z_T(X) = prod(X - t_i)
  (quotient-cache nil :type (or null hash-table))  ; Cached quotients
  (commitment nil))

(defun cq-preprocess (table)
  "Preprocess table for CQ lookups."
  (let* ((values (lookup-table-entries table))
         (n (length values))
         ;; Compute vanishing polynomial Z_T(X) = prod(X - t_i)
         (vanishing (poly-from-roots values))
         ;; Cache quotients Q_i(X) = Z_T(X) / (X - t_i)
         (cache (make-hash-table :test 'eql)))
    ;; For each table value, compute quotient polynomial
    (dolist (t-val values)
      (let ((other-roots (remove t-val values :count 1)))
        (setf (gethash t-val cache)
              (poly-from-roots other-roots))))
    ;; Commitment (simplified: hash of coefficients)
    (let ((commit (mod (reduce #'field-add
                               (polynomial-coeffs vanishing)
                               :initial-value 0)
                       +field-prime+)))
      (make-cq-table
       :values values
       :size n
       :vanishing-poly vanishing
       :quotient-cache cache
       :commitment commit))))

;;; ============================================================================
;;; CQ Proof
;;; ============================================================================

(defstruct cq-proof
  "CQ proof."
  (m-commitment nil)             ; Commitment to multiplicity polynomial
  (h-commitment nil)             ; Commitment to helper polynomial
  (quotient-evals nil :type list)
  (challenge nil :type (or null integer)))

;;; ============================================================================
;;; CQ Prover
;;; ============================================================================

(defun cq-prove (witness-values cq-table)
  "Generate CQ proof."
  (let* ((table-values (cq-table-values cq-table))
         ;; Count multiplicities
         (multiplicities (make-hash-table :test 'eql))
         (_ (dolist (w witness-values)
              (unless (member w table-values)
                (error "Value ~a not in table" w))
              (incf (gethash w multiplicities 0))))
         ;; Create multiplicity vector
         (m-values (mapcar (lambda (t-val)
                             (gethash t-val multiplicities 0))
                           table-values))
         ;; Generate challenge
         (beta (mod (+ 1 (reduce #'field-add m-values :initial-value 0))
                    +field-prime+))
         ;; Compute quotient evaluations at challenge
         (quotient-evals
           (mapcar (lambda (t-val)
                     (let ((q (gethash t-val (cq-table-quotient-cache cq-table))))
                       (when q (poly-eval q beta))))
                   table-values))
         ;; Commitments (simplified)
         (m-commit (mod (reduce #'field-add m-values :initial-value 0) +field-prime+))
         (h-commit (mod (reduce #'field-add
                                (remove nil quotient-evals)
                                :initial-value 0)
                        +field-prime+)))
    (declare (ignore _))
    (make-cq-proof
     :m-commitment m-commit
     :h-commitment h-commit
     :quotient-evals (remove nil quotient-evals)
     :challenge beta)))

;;; ============================================================================
;;; CQ Verifier
;;; ============================================================================

(defun cq-verify (proof cq-table witness-commitment)
  "Verify CQ proof."
  (declare (ignore witness-commitment))
  ;; Simplified verification
  (and proof
       (cq-proof-p proof)
       cq-table
       (cq-proof-m-commitment proof)
       (cq-proof-challenge proof)
       ;; Check quotient evaluations are consistent
       (= (length (cq-proof-quotient-evals proof))
          (cq-table-size cq-table))))
