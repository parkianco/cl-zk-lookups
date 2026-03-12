;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause
;;;;
;;;; LogUp - Logarithmic derivative lookup argument

(in-package :cl-zk-lookups)

;;; ============================================================================
;;; LogUp Proof Structure
;;; ============================================================================

(defstruct logup-proof
  "LogUp proof using logarithmic derivatives."
  (accumulator-commitment nil)    ; Commitment to accumulator
  (inverse-commitments nil :type list)  ; Commitments to 1/(X - a_i)
  (final-sum nil :type (or null integer))
  (challenge nil :type (or null integer)))

;;; ============================================================================
;;; LogUp Core
;;; ============================================================================

(defun logup-inverse-sum (values alpha)
  "Compute sum of 1/(alpha - v_i) for all values."
  (let ((sum 0))
    (dolist (v values)
      (let ((diff (field-sub alpha v)))
        (unless (zerop diff)
          (setf sum (field-add sum (field-inv diff))))))
    sum))

(defun logup-accumulator (witness-values table-values alpha)
  "Compute LogUp accumulator.
   For each witness value w, contribute +1/(alpha - w).
   For each table value t with multiplicity m, contribute -m/(alpha - t)."
  (let ((multiplicities (make-hash-table :test 'eql)))
    ;; Count multiplicities in witness
    (dolist (w witness-values)
      (incf (gethash w multiplicities 0)))
    ;; Witness contribution: sum of 1/(alpha - w_i)
    (let ((witness-sum (logup-inverse-sum witness-values alpha)))
      ;; Table contribution: sum of -m_t/(alpha - t)
      (let ((table-sum 0))
        (dolist (t-val table-values)
          (let ((m (gethash t-val multiplicities 0))
                (diff (field-sub alpha t-val)))
            (unless (zerop diff)
              (setf table-sum
                    (field-add table-sum
                               (field-mul m (field-inv diff)))))))
        ;; Final: witness-sum - table-sum should equal 0 if valid
        (values (field-sub witness-sum table-sum)
                witness-sum
                table-sum)))))

;;; ============================================================================
;;; LogUp Prover
;;; ============================================================================

(defun logup-prove (witness-values table)
  "Generate LogUp proof."
  (let* ((table-values (lookup-table-entries table))
         ;; Verify all witness values are in table
         (_ (dolist (v witness-values)
              (unless (table-contains-p table v)
                (error "Value ~a not in lookup table" v))))
         ;; Generate challenge
         (alpha (mod (+ 1
                        (reduce #'field-add witness-values :initial-value 0)
                        (reduce #'field-add table-values :initial-value 0))
                     +field-prime+))
         ;; Compute accumulator
         (final-sum (logup-accumulator witness-values table-values alpha))
         ;; Compute inverses for witness
         (inverses (mapcar (lambda (w)
                             (let ((diff (field-sub alpha w)))
                               (if (zerop diff) 0 (field-inv diff))))
                           witness-values))
         ;; Commit (simplified)
         (acc-commit (mod (reduce #'field-add inverses :initial-value 0) +field-prime+)))
    (declare (ignore _))
    (make-logup-proof
     :accumulator-commitment acc-commit
     :inverse-commitments (list (mod (reduce #'+ inverses) +field-prime+))
     :final-sum final-sum
     :challenge alpha)))

;;; ============================================================================
;;; LogUp Verifier
;;; ============================================================================

(defun logup-verify (proof table witness-commitment)
  "Verify LogUp proof."
  (declare (ignore table witness-commitment))
  ;; Simplified verification: check structure and that final sum is 0
  (and proof
       (logup-proof-p proof)
       (logup-proof-accumulator-commitment proof)
       (zerop (logup-proof-final-sum proof))))
