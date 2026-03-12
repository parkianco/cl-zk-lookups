# cl-zk-lookups

Pure Common Lisp implementation of zero-knowledge lookup arguments.

## Features

- **Plookup**: Grand product-based lookup argument
- **LogUp**: Logarithmic derivative lookup argument
- **CQ**: Cached quotients for large tables
- Polynomial operations and Lagrange interpolation
- Multi-column table support
- Zero external dependencies

## Installation

```bash
cd ~/quicklisp/local-projects/
git clone https://github.com/parkianco/cl-zk-lookups.git
```

```lisp
(asdf:load-system :cl-zk-lookups)
```

## Quick Start

```lisp
(use-package :cl-zk-lookups)

;; Create lookup table
(let* ((table (make-lookup-table-from-list '(0 1 2 3 4 5 6 7)))
       (witness '(1 3 5 7 1 3))  ; Values to look up
       ;; Generate proof
       (proof (plookup-prove witness table)))
  ;; Verify
  (plookup-verify proof table nil))
```

## Lookup Arguments

### Plookup

Based on sorted vectors and grand products:

```lisp
(let* ((table (make-lookup-table-from-list '(0 1 4 9 16 25)))
       (witness '(1 4 9))
       (proof (plookup-prove witness table)))
  (plookup-verify proof table nil))  ; => T
```

### LogUp

Uses logarithmic derivatives for efficiency with sparse lookups:

```lisp
(let* ((table (make-lookup-table-from-list (loop for i below 1000 collect i)))
       (witness '(42 100 500))  ; Sparse lookup
       (proof (logup-prove witness table)))
  (logup-verify proof table nil))  ; => T
```

### CQ (Cached Quotients)

Preprocessed tables for faster proving:

```lisp
;; Preprocess table once
(let* ((table (make-lookup-table-from-list '(0 1 2 3 4 5)))
       (cq-table (cq-preprocess table))
       ;; Multiple proofs share preprocessing
       (proof (cq-prove '(1 2 3) cq-table)))
  (cq-verify proof cq-table nil))
```

## API Reference

### Tables
- `make-lookup-table-from-list` - Create table from values
- `table-contains-p` - Check membership
- `table-index-of` - Get index of value

### Plookup
- `plookup-prove` - Generate proof
- `plookup-verify` - Verify proof
- `plookup-sorted-vector` - Create sorted witness+table vector

### LogUp
- `logup-prove` - Generate proof
- `logup-verify` - Verify proof
- `logup-inverse-sum` - Compute sum of inverses

### CQ
- `cq-preprocess` - Preprocess table
- `cq-prove` - Generate proof
- `cq-verify` - Verify proof

### Unified
- `verify-lookup` - Auto-detect and verify any proof type
- `batch-verify-lookups` - Verify multiple proofs
- `choose-lookup-type` - Suggest optimal argument

## Polynomials

```lisp
;; Create polynomial 1 + 2x + 3x^2
(let ((p (make-polynomial :coeffs '(1 2 3))))
  (poly-eval p 5))  ; => 1 + 10 + 75 = 86

;; Interpolate through points
(poly-interpolate '(0 1 2) '(1 4 9))  ; 1 + 2x + x^2
```

## License

BSD-3-Clause. See [LICENSE](LICENSE).

## Author

Parkian Company LLC
