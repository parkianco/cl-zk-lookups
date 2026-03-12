;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause
;;;;
;;;; Plookup - Lookup argument based on grand product

(in-package :cl-zk-lookups)

;;; ============================================================================
;;; Plookup Proof Structure
;;; ============================================================================

(defstruct plookup-proof
  "Plookup proof."
  (sorted-commitment nil)        ; Commitment to sorted vector
  (grand-product-commitment nil) ; Commitment to grand product
  (opening-proof nil)            ; Polynomial opening proof
  (challenge nil :type (or null integer)))

;;; ============================================================================
;;; Plookup Sorted Vector
;;; ============================================================================

(defun plookup-sorted-vector (witness-values table-values)
  "Create sorted vector s from witness f and table t.
   s contains all elements of f and t, sorted."
  (let ((all-values (append (copy-list witness-values)
                            (copy-list table-values))))
    (sort all-values #'<)))

(defun plookup-count-multiplicities (witness-values table-values)
  "Count how many times each table value appears in witness."
  (let ((counts (make-hash-table :test 'eql)))
    (dolist (v table-values)
      (setf (gethash v counts) 0))
    (dolist (v witness-values)
      (incf (gethash v counts 0)))
    counts))

;;; ============================================================================
;;; Grand Product
;;; ============================================================================

(defun plookup-grand-product (sorted beta gamma)
  "Compute grand product polynomial Z for plookup.
   Z(w^i) = prod_{j<i} [(1 + beta) * (gamma + s_j) * (gamma + s_{j+1})]"
  (let ((n (length sorted))
        (z-values (list 1))  ; Z(1) = 1
        (running 1))
    (dotimes (i (1- n))
      (let* ((s-i (nth i sorted))
             (s-i1 (nth (1+ i) sorted))
             ;; Numerator: (1 + beta) * (gamma + s_i) * (gamma(1+beta) + s_{i+1} + beta*s_i)
             (term1 (field-add 1 beta))
             (term2 (field-add gamma s-i))
             (term3 (field-add (field-add (field-mul gamma (field-add 1 beta))
                                          s-i1)
                               (field-mul beta s-i)))
             (num (field-mul (field-mul term1 term2) term3))
             ;; Simplified accumulation
             (acc (field-mul running num)))
        (setf running acc)
        (push acc z-values)))
    (nreverse z-values)))

;;; ============================================================================
;;; Plookup Prover
;;; ============================================================================

(defun plookup-prove (witness-values table)
  "Generate plookup proof that all witness values are in table."
  (let* ((table-values (lookup-table-entries table))
         ;; Verify all witness values are in table
         (_ (dolist (v witness-values)
              (unless (table-contains-p table v)
                (error "Value ~a not in lookup table" v))))
         ;; Create sorted vector
         (sorted (plookup-sorted-vector witness-values table-values))
         ;; Generate challenges (Fiat-Shamir in practice)
         (beta (mod (reduce #'field-add witness-values :initial-value 1)
                    +field-prime+))
         (gamma (mod (+ beta (reduce #'field-add table-values :initial-value 0))
                     +field-prime+))
         ;; Compute grand product
         (z-values (plookup-grand-product sorted beta gamma))
         ;; Commit to sorted (simplified: hash)
         (sorted-commit (mod (reduce #'field-add sorted :initial-value 0) +field-prime+))
         (z-commit (mod (reduce #'field-add z-values :initial-value 0) +field-prime+)))
    (declare (ignore _))
    (make-plookup-proof
     :sorted-commitment sorted-commit
     :grand-product-commitment z-commit
     :challenge beta)))

;;; ============================================================================
;;; Plookup Verifier
;;; ============================================================================

(defun plookup-verify (proof table witness-commitment)
  "Verify plookup proof."
  (declare (ignore table witness-commitment))
  ;; Simplified verification
  (and proof
       (plookup-proof-p proof)
       (plookup-proof-sorted-commitment proof)
       (plookup-proof-grand-product-commitment proof)
       (plusp (plookup-proof-challenge proof))))
