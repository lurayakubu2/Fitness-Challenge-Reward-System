(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u2000))
(define-constant ERR_BADGE_NOT_FOUND (err u2001))
(define-constant ERR_ALREADY_EARNED (err u2002))

(define-non-fungible-token achievement-badge uint)
(define-data-var badge-counter uint u0)

(define-map badge-metadata uint {
    name: (string-ascii 40),
    description: (string-ascii 100),
    requirement-type: (string-ascii 20),
    requirement-value: uint
})

(define-map user-badges principal (list 20 uint))

(define-private (mint-badge (badge-id uint) (recipient principal))
    (begin
        (try! (nft-mint? achievement-badge badge-id recipient))
        (map-set user-badges recipient 
            (unwrap-panic (as-max-len? 
                (append (default-to (list) (map-get? user-badges recipient)) badge-id) 
                u20)))
        (ok badge-id)
    )
)

(define-public (create-badge (name (string-ascii 40)) (description (string-ascii 100)) (requirement-type (string-ascii 20)) (requirement-value uint))
    (let ((badge-id (+ (var-get badge-counter) u1)))
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (map-set badge-metadata badge-id {
            name: name,
            description: description,
            requirement-type: requirement-type,
            requirement-value: requirement-value
        })
        (var-set badge-counter badge-id)
        (ok badge-id)
    )
)

(define-public (check-and-award-badges (user principal))
    (let ((user-data-opt (contract-call? .Fitness-Challenge-Reward-System get-user-data user))
          (user-badges-list (default-to (list) (map-get? user-badges user))))
        (match user-data-opt
            user-data
            (begin
                (if (and (>= (get total-activities user-data) u10)
                         (is-none (index-of user-badges-list u1)))
                    (try! (mint-badge u1 user))
                    u0)
                
                (if (and (>= (get total-activities user-data) u50)
                         (is-none (index-of user-badges-list u2)))
                    (try! (mint-badge u2 user))
                    u0)
                
                (if (and (>= (get total-rewards user-data) u1000)
                         (is-none (index-of user-badges-list u3)))
                    (try! (mint-badge u3 user))
                    u0)
                
                (ok true)
            )
            (ok false)
        )
    )
)

(define-public (initialize-badges)
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (try! (create-badge "First Steps" "Complete 10 activities" "activities" u10))
        (try! (create-badge "Fitness Warrior" "Complete 50 activities" "activities" u50))
        (try! (create-badge "Token Collector" "Earn 1000+ reward tokens" "rewards" u1000))
        (ok true)
    )
)

(define-read-only (get-badge-metadata (badge-id uint))
    (map-get? badge-metadata badge-id)
)

(define-read-only (get-user-badges (user principal))
    (default-to (list) (map-get? user-badges user))
)

(define-read-only (has-badge (user principal) (badge-id uint))
    (is-some (index-of (get-user-badges user) badge-id))
)

(define-read-only (get-badge-owner (badge-id uint))
    (nft-get-owner? achievement-badge badge-id)
)

