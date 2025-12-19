;; teeboo-streak contract
;; Decentralized Habit Tracker and On-chain Journaling System
;; Built for Stacks (Clarity 4)

;; Implement SIP-009 NFT Trait for Badge rewards
(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

(define-non-fungible-token streak-badge uint)

;; --- DATA MAPS ---

;; Store user statistics
(define-map user-stats
  principal
  {
    current-streak: uint,
    max-streak: uint,
    last-checkin: uint,
    total-checkins: uint
  }
)

;; Store journal entries (unique per user and index)
(define-map diary-entries
  { user: principal, id: uint }
  {
    content: (string-utf8 1024),
    timestamp: uint
  }
)

;; Keep track of how many entries each user has
(define-map entry-count principal uint)

(define-data-var last-token-id uint u0)

;; --- CONSTANTS ---

(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ALREADY_CHECKED_IN (err u101))
(define-constant ERR_STREAK_NOT_MET (err u102))
(define-constant BLOCKS_PER_DAY u144) ;; Stacks blocks per day (~10 mins/block)

;; --- PUBLIC FUNCTIONS ---

;; Record a daily activity and update streaks
(define-public (check-in)
  (let
    (
      (user tx-sender)
      (current-height burn-block-height)
      (stats (default-to { current-streak: u0, max-streak: u0, last-checkin: u0, total-checkins: u0 } (map-get? user-stats user)))
      (last-checkin (get last-checkin stats))
      (diff (- current-height last-checkin))
    )
    ;; Prevent multiple check-ins within the same day (144 blocks)
    (asserts! (or (is-eq last-checkin u0) (> diff BLOCKS_PER_DAY)) ERR_ALREADY_CHECKED_IN)
    
    (let
      (
        ;; If more than 2 days passed (288 blocks), streak resets to 1. Otherwise increment.
        (is-streak-active (< diff (* BLOCKS_PER_DAY u2)))
        (new-streak (if (or (is-eq last-checkin u0) is-streak-active) (+ (get current-streak stats) u1) u1))
        (new-max (if (> new-streak (get max-streak stats)) new-streak (get max-streak stats)))
      )
      (map-set user-stats user
        {
          current-streak: new-streak,
          max-streak: new-max,
          last-checkin: current-height,
          total-checkins: (+ (get total-checkins stats) u1)
        }
      )
      (ok true)
    )
  )
)

;; Add a new journal entry to the blockchain
(define-public (add-diary-entry (content (string-utf8 1024)))
  (let
    (
      (user tx-sender)
      (count (default-to u0 (map-get? entry-count user)))
    )
    (map-set diary-entries { user: user, id: count } { content: content, timestamp: burn-block-height })
    (map-set entry-count user (+ count u1))
    (ok count)
  )
)

;; Claim a permanent NFT badge if you reached a 7-day streak
(define-public (claim-streak-nft)
  (let
    (
      (user tx-sender)
      (stats (unwrap! (map-get? user-stats user) ERR_STREAK_NOT_MET))
      (new-id (+ (var-get last-token-id) u1))
    )
    ;; Must have at least 7 days streak record
    (asserts! (>= (get max-streak stats) u7) ERR_STREAK_NOT_MET)
    
    (try! (nft-mint? streak-badge new-id user))
    (var-set last-token-id new-id)
    (ok new-id)
  )
)

;; --- READ-ONLY FUNCTIONS (GETTERS) ---

(define-read-only (get-user (user principal))
  (ok (default-to { current-streak: u0, max-streak: u0, last-checkin: u0, total-checkins: u0 } (map-get? user-stats user)))
)

(define-read-only (get-entry-count (user principal))
  (ok (default-to u0 (map-get? entry-count user)))
)

(define-read-only (get-diary-entry (user principal) (id uint))
  (map-get? diary-entries { user: user, id: id })
)

;; --- SIP-009 NFT REQUIREMENTS ---

(define-read-only (get-last-token-id)
  (ok (var-get last-token-id))
)

(define-read-only (get-token-uri (id uint))
  (ok none)
)

(define-read-only (get-owner (id uint))
  (ok (nft-get-owner? streak-badge id))
)

(define-public (transfer (id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR_NOT_AUTHORIZED)
    (nft-transfer? streak-badge id sender recipient)
  )
)

;; Helper for frontend to check if user has any badges
(define-read-only (get-balance (user principal))
  (ok u0) ;; In a production app, you might iterate or use an indexer for this
)