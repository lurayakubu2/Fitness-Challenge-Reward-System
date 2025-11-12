(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u4000))
(define-constant ERR_CODE_EXISTS (err u4001))
(define-constant ERR_INVALID_CODE (err u4002))
(define-constant ERR_SELF_REFERRAL (err u4003))
(define-constant ERR_ALREADY_REFERRED (err u4004))
(define-constant REFERRER_REWARD u200)
(define-constant REFEREE_REWARD u100)

(define-map referral-codes (string-ascii 10) principal)
(define-map user-referral-data principal {
    referral-code: (string-ascii 10),
    referred-by: (optional principal),
    total-referrals: uint,
    referral-rewards: uint,
    first-activity-completed: bool
})

(define-public (create-referral-code (code (string-ascii 10)))
    (let ((existing-data (map-get? user-referral-data tx-sender)))
        (asserts! (is-none (map-get? referral-codes code)) ERR_CODE_EXISTS)
        (map-set referral-codes code tx-sender)
        (match existing-data
            data (map-set user-referral-data tx-sender (merge data {referral-code: code}))
            (map-set user-referral-data tx-sender {
                referral-code: code,
                referred-by: none,
                total-referrals: u0,
                referral-rewards: u0,
                first-activity-completed: false
            })
        )
        (ok code)
    )
)

(define-public (register-with-referral (code (string-ascii 10)))
    (let (
        (referrer (unwrap! (map-get? referral-codes code) ERR_INVALID_CODE))
        (existing-data (map-get? user-referral-data tx-sender))
    )
        (asserts! (not (is-eq referrer tx-sender)) ERR_SELF_REFERRAL)
        (asserts! (is-none existing-data) ERR_ALREADY_REFERRED)
        (map-set user-referral-data tx-sender {
            referral-code: "",
            referred-by: (some referrer),
            total-referrals: u0,
            referral-rewards: u0,
            first-activity-completed: false
        })
        (ok referrer)
    )
)

(define-public (claim-referral-bonus)
    (let (
        (referee-data (unwrap! (map-get? user-referral-data tx-sender) ERR_UNAUTHORIZED))
        (referrer (unwrap! (get referred-by referee-data) ERR_UNAUTHORIZED))
        (referrer-data (unwrap! (map-get? user-referral-data referrer) ERR_UNAUTHORIZED))
    )
        (asserts! (not (get first-activity-completed referee-data)) ERR_ALREADY_REFERRED)
        (map-set user-referral-data tx-sender (merge referee-data {first-activity-completed: true}))
        (map-set user-referral-data referrer (merge referrer-data {
            total-referrals: (+ (get total-referrals referrer-data) u1),
            referral-rewards: (+ (get referral-rewards referrer-data) REFERRER_REWARD)
        }))
        (ok {referrer: referrer, referrer-bonus: REFERRER_REWARD, referee-bonus: REFEREE_REWARD})
    )
)

(define-read-only (get-referrer (code (string-ascii 10)))
    (map-get? referral-codes code)
)

(define-read-only (get-user-referral-stats (user principal))
    (map-get? user-referral-data user)
)

(define-read-only (get-referral-rewards (user principal))
    (match (map-get? user-referral-data user)
        data (ok (get referral-rewards data))
        (ok u0)
    )
)
