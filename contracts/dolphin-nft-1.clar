
(define-non-fungible-token dolphin-streak-nft uint)
(define-data-var last-token-id uint u0)


(define-constant BLOCKS_PER_DAY u144)
(define-constant ERR_NOT_CHECKED_IN u101)
(define-constant ERR_ALREADY_MINTED_TODAY u106)


(define-map last-mint-map principal uint)

(define-read-only (get-day-index)
  (/ burn-block-height BLOCKS_PER_DAY)
)


(define-public (mint)
  (let (
    (user tx-sender)
    (today (get-day-index))
    (next-id (+ (var-get last-token-id) u1))
    
    (streak-data (unwrap-panic (contract-call? .streak-reg get-user user)))
    
    (user-last-check-in (get last-day streak-data))
    (user-last-mint (default-to u0 (map-get? last-mint-map user)))
  )


    (asserts! (is-eq today user-last-check-in) (err ERR_NOT_CHECKED_IN))
    

    (asserts! (< user-last-mint today) (err ERR_ALREADY_MINTED_TODAY))


    (try! (nft-mint? dolphin-streak-nft next-id user))
    

    (map-set last-mint-map user today)
    (var-set last-token-id next-id)
    
    (ok next-id)
  )
)


(define-read-only (get-last-token-id)
  (ok (var-get last-token-id))
)

(define-read-only (get-token-uri (token-id uint))
  (ok (some u"https://stackstreak.vercel.app/assets/dolphin.json"))
)

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? dolphin-streak-nft token-id))
)

(define-read-only (transfer (token-id uint) (sender principal) (recipient principal))
  (err u403)
)