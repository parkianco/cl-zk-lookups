;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause
;;;;
;;;; Lookup table structures

(in-package :cl-zk-lookups)

;;; ============================================================================
;;; Lookup Table
;;; ============================================================================

(defstruct lookup-table
  "Table of valid lookup values."
  (entries nil :type list)
  (size 0 :type integer)
  (index-map nil :type (or null hash-table)))  ; value -> index

(defun make-lookup-table-from-list (values)
  "Create lookup table from list of values."
  (let ((index-map (make-hash-table :test 'eql))
        (normalized nil))
    (loop for v in values
          for i from 0 do
      (let ((norm (mod v +field-prime+)))
        (push norm normalized)
        (setf (gethash norm index-map) i)))
    (make-lookup-table
     :entries (nreverse normalized)
     :size (length values)
     :index-map index-map)))

(defun table-contains-p (table value)
  "Check if value is in table."
  (gethash (mod value +field-prime+)
           (lookup-table-index-map table)))

(defun table-index-of (table value)
  "Get index of value in table (or NIL)."
  (gethash (mod value +field-prime+)
           (lookup-table-index-map table)))

(defun table-to-vector (table)
  "Convert table to vector."
  (coerce (lookup-table-entries table) 'vector))

;;; ============================================================================
;;; Multi-Column Table
;;; ============================================================================

(defstruct multi-table
  "Multi-column lookup table."
  (columns nil :type list)      ; List of column vectors
  (num-rows 0 :type integer)
  (num-cols 0 :type integer)
  (row-map nil :type (or null hash-table)))  ; row-hash -> index

(defun multi-table-row (table row-idx)
  "Get row as list of values."
  (mapcar (lambda (col) (nth row-idx col))
          (multi-table-columns table)))

(defun multi-table-contains-row-p (table row)
  "Check if row exists in table."
  (let ((hash (row-hash row)))
    (gethash hash (multi-table-row-map table))))

(defun row-hash (row)
  "Hash a row for lookup."
  (reduce (lambda (h v)
            (field-add (field-mul h 31337) v))
          row
          :initial-value 0))

(defun make-multi-table-from-lists (columns)
  "Create multi-column table from list of column lists."
  (let* ((num-rows (length (first columns)))
         (num-cols (length columns))
         (row-map (make-hash-table :test 'eql)))
    (dotimes (i num-rows)
      (let ((row (mapcar (lambda (col) (nth i col)) columns)))
        (setf (gethash (row-hash row) row-map) i)))
    (make-multi-table
     :columns columns
     :num-rows num-rows
     :num-cols num-cols
     :row-map row-map)))
