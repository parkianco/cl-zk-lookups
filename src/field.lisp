;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause
;;;;
;;;; Field arithmetic

(in-package :cl-zk-lookups)

;;; ============================================================================
;;; BN254 Scalar Field
;;; ============================================================================

(defconstant +field-prime+
  21888242871839275222246405745257275088548364400416034343698204186575808495617
  "BN254 scalar field prime.")

(defun field-add (a b)
  "Add two field elements."
  (mod (+ a b) +field-prime+))

(defun field-sub (a b)
  "Subtract two field elements."
  (mod (- a b) +field-prime+))

(defun field-mul (a b)
  "Multiply two field elements."
  (mod (* a b) +field-prime+))

(defun field-neg (a)
  "Negate a field element."
  (mod (- +field-prime+ a) +field-prime+))

(defun field-pow (base exp)
  "Modular exponentiation."
  (let ((result 1)
        (b (mod base +field-prime+))
        (e exp))
    (loop while (plusp e) do
      (when (oddp e)
        (setf result (field-mul result b)))
      (setf b (field-mul b b))
      (setf e (ash e -1)))
    result))

(defun field-inv (a)
  "Multiplicative inverse."
  (when (zerop a)
    (error "Cannot invert zero"))
  (field-pow a (- +field-prime+ 2)))
