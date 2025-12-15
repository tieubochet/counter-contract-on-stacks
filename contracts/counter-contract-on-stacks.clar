;; Simple Counter Contract (Clarity 4)

(define-data-var count uint u0)
(define-data-var registration-fee uint u10)
(define-data-var contract-owner (optional principal) none)


(define-read-only (get-count)
  (var-get count)
)


(define-read-only (get-owner-as-string (owner principal))
  (to-ascii? owner)
)


(define-read-only (get-registration-fee-as-string)
  (to-ascii? (var-get registration-fee))
)

(define-public (increment)
  (begin
    (var-set count (+ (var-get count) u1))
    (ok (var-get count))
  )
)

(define-public (set-owner (owner principal))
  (if (is-none (var-get contract-owner))
    (begin
      (var-set contract-owner (some owner))
      (ok owner)
    )
    (err u401)
  )
)