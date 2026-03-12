;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause
;;;;
;;;; Polynomial operations for lookup arguments

(in-package :cl-zk-lookups)

;;; ============================================================================
;;; Polynomial Structure
;;; ============================================================================

(defstruct polynomial
  "Polynomial in coefficient form (coeffs[i] is coefficient of x^i)."
  (coeffs nil :type list))

(defun poly-degree (p)
  "Degree of polynomial."
  (1- (length (polynomial-coeffs p))))

(defun poly-eval (p x)
  "Evaluate polynomial at point x using Horner's method."
  (let ((coeffs (reverse (polynomial-coeffs p)))
        (result 0))
    (dolist (c coeffs)
      (setf result (field-add (field-mul result x) c)))
    result))

;;; ============================================================================
;;; Polynomial Arithmetic
;;; ============================================================================

(defun poly-add (p1 p2)
  "Add two polynomials."
  (let* ((c1 (polynomial-coeffs p1))
         (c2 (polynomial-coeffs p2))
         (len (max (length c1) (length c2)))
         (result nil))
    (dotimes (i len)
      (let ((a (if (< i (length c1)) (nth i c1) 0))
            (b (if (< i (length c2)) (nth i c2) 0)))
        (push (field-add a b) result)))
    (make-polynomial :coeffs (nreverse result))))

(defun poly-scale (p scalar)
  "Scale polynomial by scalar."
  (make-polynomial
   :coeffs (mapcar (lambda (c) (field-mul c scalar))
                   (polynomial-coeffs p))))

(defun poly-mul (p1 p2)
  "Multiply two polynomials."
  (let* ((c1 (polynomial-coeffs p1))
         (c2 (polynomial-coeffs p2))
         (n1 (length c1))
         (n2 (length c2))
         (result (make-list (+ n1 n2 -1) :initial-element 0)))
    (dotimes (i n1)
      (dotimes (j n2)
        (setf (nth (+ i j) result)
              (field-add (nth (+ i j) result)
                         (field-mul (nth i c1) (nth j c2))))))
    (make-polynomial :coeffs result)))

;;; ============================================================================
;;; Polynomial Construction
;;; ============================================================================

(defun poly-from-roots (roots)
  "Construct polynomial from roots: prod(x - r_i)."
  (let ((result (make-polynomial :coeffs '(1))))
    (dolist (r roots)
      (let ((factor (make-polynomial :coeffs (list (field-neg r) 1))))
        (setf result (poly-mul result factor))))
    result))

(defun poly-lagrange-basis (points i x)
  "Compute i-th Lagrange basis polynomial at x."
  (let ((xi (nth i points))
        (num 1)
        (denom 1))
    (dotimes (j (length points))
      (unless (= i j)
        (let ((xj (nth j points)))
          (setf num (field-mul num (field-sub x xj)))
          (setf denom (field-mul denom (field-sub xi xj))))))
    (field-mul num (field-inv denom))))

(defun poly-interpolate (points values)
  "Lagrange interpolation to find polynomial through points."
  (let ((n (length points))
        (coeffs (make-list (length points) :initial-element 0)))
    (dotimes (i n)
      (let ((li-coeffs (list 1))
            (denom 1))
        ;; Build L_i(x) = prod_{j!=i} (x - x_j) / (x_i - x_j)
        (dotimes (j n)
          (unless (= i j)
            (let ((xj (nth j points))
                  (xi (nth i points)))
              (setf denom (field-mul denom (field-sub xi xj)))
              ;; Multiply by (x - x_j)
              (let ((new-coeffs (make-list (1+ (length li-coeffs)) :initial-element 0)))
                (dotimes (k (length li-coeffs))
                  (incf (nth k new-coeffs) (field-mul (nth k li-coeffs) (field-neg xj)))
                  (incf (nth (1+ k) new-coeffs) (nth k li-coeffs)))
                (setf li-coeffs (mapcar (lambda (c) (mod c +field-prime+)) new-coeffs))))))
        ;; Scale by y_i / denom and add to result
        (let ((scale (field-mul (nth i values) (field-inv denom))))
          (dotimes (k (length li-coeffs))
            (when (< k (length coeffs))
              (setf (nth k coeffs)
                    (field-add (nth k coeffs)
                               (field-mul scale (nth k li-coeffs)))))))))
    (make-polynomial :coeffs coeffs)))
