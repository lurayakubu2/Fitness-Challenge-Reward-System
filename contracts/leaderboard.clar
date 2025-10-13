(define-constant ERR_NOT_INITIALIZED (err u3000))
(define-constant ERR_INVALID_USER (err u3001))
(define-constant POINTS_PER_ACTIVITY u100)
(define-constant POINTS_PER_CALORIE u1)
(define-constant STREAK_BONUS_MULTIPLIER u50)

(define-map user-scores principal {
    total-points: uint,
    last-activity-block: uint,
    current-streak: uint,
    best-streak: uint,
    rank: uint
})

(define-data-var total-users uint u0)

(define-public (update-score (user principal) (calories uint))
    (let (
        (current-score (default-to 
            {total-points: u0, last-activity-block: u0, current-streak: u0, best-streak: u0, rank: u0} 
            (map-get? user-scores user)))
        (base-points (+ POINTS_PER_ACTIVITY (* calories POINTS_PER_CALORIE)))
        (blocks-since-last (if (> (get last-activity-block current-score) u0)
            (- stacks-block-height (get last-activity-block current-score))
            u0))
        (new-streak (if (and (> blocks-since-last u0) (<= blocks-since-last u144))
            (+ (get current-streak current-score) u1)
            u1))
        (streak-bonus (* new-streak STREAK_BONUS_MULTIPLIER))
        (total-new-points (+ base-points streak-bonus))
    )
        (map-set user-scores user {
            total-points: (+ (get total-points current-score) total-new-points),
            last-activity-block: stacks-block-height,
            current-streak: new-streak,
            best-streak: (if (> new-streak (get best-streak current-score)) 
                new-streak 
                (get best-streak current-score)),
            rank: (get rank current-score)
        })
        (if (is-eq (get total-points current-score) u0)
            (var-set total-users (+ (var-get total-users) u1))
            true)
        (ok total-new-points)
    )
)

(define-read-only (get-user-score (user principal))
    (map-get? user-scores user)
)

(define-read-only (get-leaderboard-position (user principal))
    (match (map-get? user-scores user)
        score (ok (get total-points score))
        ERR_INVALID_USER
    )
)

(define-read-only (compare-users (user1 principal) (user2 principal))
    (let (
        (score1 (default-to {total-points: u0, last-activity-block: u0, current-streak: u0, best-streak: u0, rank: u0} 
            (map-get? user-scores user1)))
        (score2 (default-to {total-points: u0, last-activity-block: u0, current-streak: u0, best-streak: u0, rank: u0} 
            (map-get? user-scores user2)))
    )
        (ok (> (get total-points score1) (get total-points score2)))
    )
)

(define-read-only (get-total-leaderboard-users)
    (ok (var-get total-users))
)
