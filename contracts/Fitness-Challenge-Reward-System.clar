(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u1000))
(define-constant ERR_INVALID_CHALLENGE (err u1001))
(define-constant ERR_ALREADY_REGISTERED (err u1002))
(define-constant ERR_NOT_REGISTERED (err u1003))
(define-constant ERR_INSUFFICIENT_BALANCE (err u1004))
(define-constant ERR_CHALLENGE_ENDED (err u1005))
(define-constant ERR_INVALID_ACTIVITY (err u1006))
(define-constant ERR_ALREADY_VERIFIED (err u1007))

(define-fungible-token fitness-token)

(define-map users principal {
    registered: bool,
    total-activities: uint,
    total-rewards: uint,
    active-challenges: (list 10 uint)
})

(define-map challenges uint {
    creator: principal,
    name: (string-ascii 50),
    description: (string-ascii 200),
    reward-per-activity: uint,
    max-participants: uint,
    current-participants: uint,
    start-block: uint,
    end-block: uint,
    is-active: bool
})

(define-map activities uint {
    user: principal,
    challenge-id: uint,
    activity-type: (string-ascii 20),
    duration-minutes: uint,
    calories-burned: uint,
    verified: bool,
    verification-block: uint,
    reward-claimed: bool
})

(define-map challenge-participants {challenge-id: uint, user: principal} bool)
(define-data-var challenge-counter uint u0)
(define-data-var activity-counter uint u0)

(define-public (register-user)
    (begin
        (asserts! (is-none (map-get? users tx-sender)) ERR_ALREADY_REGISTERED)
        (map-set users tx-sender {
            registered: true,
            total-activities: u0,
            total-rewards: u0,
            active-challenges: (list)
        })
        (ft-mint? fitness-token u1000 tx-sender)
    )
)

(define-public (create-challenge (name (string-ascii 50)) (description (string-ascii 200)) (reward-per-activity uint) (max-participants uint) (duration-blocks uint))
    (let ((challenge-id (+ (var-get challenge-counter) u1)))
        (asserts! (is-some (map-get? users tx-sender)) ERR_NOT_REGISTERED)
        (asserts! (>= (ft-get-balance fitness-token tx-sender) (* reward-per-activity max-participants u10)) ERR_INSUFFICIENT_BALANCE)
        
        (map-set challenges challenge-id {
            creator: tx-sender,
            name: name,
            description: description,
            reward-per-activity: reward-per-activity,
            max-participants: max-participants,
            current-participants: u0,
            start-block: stacks-block-height,
            end-block: (+ stacks-block-height duration-blocks),
            is-active: true
        })
        
        (var-set challenge-counter challenge-id)
        (ok challenge-id)
    )
)

(define-public (join-challenge (challenge-id uint))
    (let ((challenge (unwrap! (map-get? challenges challenge-id) ERR_INVALID_CHALLENGE))
          (user-data (unwrap! (map-get? users tx-sender) ERR_NOT_REGISTERED)))
        
        (asserts! (get is-active challenge) ERR_CHALLENGE_ENDED)
        (asserts! (< (get current-participants challenge) (get max-participants challenge)) ERR_INVALID_CHALLENGE)
        (asserts! (>= stacks-block-height (get start-block challenge)) ERR_INVALID_CHALLENGE)
        (asserts! (< stacks-block-height (get end-block challenge)) ERR_CHALLENGE_ENDED)
        
        (map-set challenge-participants {challenge-id: challenge-id, user: tx-sender} true)
        (map-set challenges challenge-id (merge challenge {current-participants: (+ (get current-participants challenge) u1)}))
        
        (ok true)
    )
)

(define-public (log-activity (challenge-id uint) (activity-type (string-ascii 20)) (duration-minutes uint) (calories-burned uint))
    (let ((activity-id (+ (var-get activity-counter) u1))
          (challenge (unwrap! (map-get? challenges challenge-id) ERR_INVALID_CHALLENGE)))
        
        (asserts! (is-some (map-get? users tx-sender)) ERR_NOT_REGISTERED)
        (asserts! (default-to false (map-get? challenge-participants {challenge-id: challenge-id, user: tx-sender})) ERR_UNAUTHORIZED)
        (asserts! (get is-active challenge) ERR_CHALLENGE_ENDED)
        (asserts! (< stacks-block-height (get end-block challenge)) ERR_CHALLENGE_ENDED)
        
        (map-set activities activity-id {
            user: tx-sender,
            challenge-id: challenge-id,
            activity-type: activity-type,
            duration-minutes: duration-minutes,
            calories-burned: calories-burned,
            verified: false,
            verification-block: u0,
            reward-claimed: false
        })
        
        (var-set activity-counter activity-id)
        (ok activity-id)
    )
)

(define-public (verify-activity (activity-id uint))
    (let ((activity (unwrap! (map-get? activities activity-id) ERR_INVALID_ACTIVITY))
          (challenge (unwrap! (map-get? challenges (get challenge-id activity)) ERR_INVALID_CHALLENGE)))
        
        (asserts! (or (is-eq tx-sender (get creator challenge)) (is-eq tx-sender CONTRACT_OWNER)) ERR_UNAUTHORIZED)
        (asserts! (not (get verified activity)) ERR_ALREADY_VERIFIED)
        
        (map-set activities activity-id (merge activity {
            verified: true,
            verification-block: stacks-block-height
        }))
        
        (ok true)
    )
)

(define-public (claim-reward (activity-id uint))
    (let ((activity (unwrap! (map-get? activities activity-id) ERR_INVALID_ACTIVITY))
          (challenge (unwrap! (map-get? challenges (get challenge-id activity)) ERR_INVALID_CHALLENGE))
          (user-data (unwrap! (map-get? users tx-sender) ERR_NOT_REGISTERED)))
        
        (asserts! (is-eq (get user activity) tx-sender) ERR_UNAUTHORIZED)
        (asserts! (get verified activity) ERR_INVALID_ACTIVITY)
        (asserts! (not (get reward-claimed activity)) ERR_INVALID_ACTIVITY)
        
        (map-set activities activity-id (merge activity {reward-claimed: true}))
        (map-set users tx-sender (merge user-data {
            total-activities: (+ (get total-activities user-data) u1),
            total-rewards: (+ (get total-rewards user-data) (get reward-per-activity challenge))
        }))
        
        (ft-mint? fitness-token (get reward-per-activity challenge) tx-sender)
    )
)

(define-public (end-challenge (challenge-id uint))
    (let ((challenge (unwrap! (map-get? challenges challenge-id) ERR_INVALID_CHALLENGE)))
        (asserts! (is-eq tx-sender (get creator challenge)) ERR_UNAUTHORIZED)
        (asserts! (get is-active challenge) ERR_CHALLENGE_ENDED)
        
        (map-set challenges challenge-id (merge challenge {is-active: false}))
        (ok true)
    )
)

(define-read-only (get-user-data (user principal))
    (map-get? users user)
)

(define-read-only (get-challenge (challenge-id uint))
    (map-get? challenges challenge-id)
)

(define-read-only (get-activity (activity-id uint))
    (map-get? activities activity-id)
)

(define-read-only (get-user-balance (user principal))
    (ft-get-balance fitness-token user)
)

(define-read-only (is-participant (challenge-id uint) (user principal))
    (default-to false (map-get? challenge-participants {challenge-id: challenge-id, user: user}))
)

(define-read-only (get-total-challenges)
    (var-get challenge-counter)
)

(define-read-only (get-total-activities)
    (var-get activity-counter)
)
