;; Weather Policy Manager Contract
;; Manages weather insurance policies, premium payments, and policy lifecycle

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-policy-expired (err u105))
(define-constant err-policy-cancelled (err u106))
(define-constant err-insufficient-premium (err u107))
(define-constant err-policy-active (err u108))

;; Data structures
(define-map weather-policies
  { policy-id: uint }
  {
    policyholder: principal,
    weather-type: (string-ascii 50),
    trigger-condition: (string-ascii 100),
    trigger-value: int,
    comparison-operator: (string-ascii 10),
    coverage-amount: uint,
    premium-amount: uint,
    coverage-start: uint,
    coverage-end: uint,
    location-lat: int,
    location-lon: int,
    status: (string-ascii 20),
    created-at: uint,
    premium-paid: bool,
    settlement-triggered: bool,
    payout-amount: uint
  }
)

(define-map policy-premiums
  { policy-id: uint }
  {
    total-premium: uint,
    paid-amount: uint,
    payment-date: uint,
    payment-address: principal
  }
)

(define-map user-policies
  { user: principal, policy-index: uint }
  { policy-id: uint }
)

(define-map user-policy-count
  { user: principal }
  { count: uint }
)

(define-map authorized-oracles
  { oracle: principal }
  {
    authorized: bool,
    specialization: (string-ascii 100),
    reputation-score: uint,
    total-submissions: uint,
    authorized-at: uint
  }
)

(define-data-var next-policy-id uint u1)
(define-data-var total-policies uint u0)
(define-data-var active-policies uint u0)
(define-data-var total-premiums-collected uint u0)
(define-data-var total-payouts-made uint u0)

;; Authorization functions
(define-public (authorize-oracle (oracle principal) (specialization (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> (len specialization) u0) err-invalid-input)
    
    (ok (map-set authorized-oracles
      { oracle: oracle }
      {
        authorized: true,
        specialization: specialization,
        reputation-score: u100,
        total-submissions: u0,
        authorized-at: burn-block-height
      }
    ))
  )
)

(define-public (revoke-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (let
      (
        (oracle-data (unwrap! (map-get? authorized-oracles { oracle: oracle }) err-not-found))
      )
      (ok (map-set authorized-oracles
        { oracle: oracle }
        (merge oracle-data { authorized: false })
      ))
    )
  )
)

(define-private (is-authorized-oracle (oracle principal))
  (match (map-get? authorized-oracles { oracle: oracle })
    some-oracle (get authorized some-oracle)
    false
  )
)

;; Core policy management functions
(define-public (create-policy
  (weather-type (string-ascii 50))
  (trigger-condition (string-ascii 100))
  (trigger-value int)
  (comparison-operator (string-ascii 10))
  (coverage-amount uint)
  (premium-amount uint)
  (coverage-days uint)
  (location-lat int)
  (location-lon int)
  )
  (let
    (
      (policy-id (var-get next-policy-id))
      (user-count (get-user-policy-count tx-sender))
      (coverage-end (+ burn-block-height coverage-days))
    )
    (asserts! (> (len weather-type) u0) err-invalid-input)
    (asserts! (> (len trigger-condition) u0) err-invalid-input)
    (asserts! (> coverage-amount u0) err-invalid-input)
    (asserts! (> premium-amount u0) err-invalid-input)
    (asserts! (> coverage-days u0) err-invalid-input)
    (asserts! (or (is-eq comparison-operator ">") (is-eq comparison-operator "<") (is-eq comparison-operator "=")) err-invalid-input)
    
    ;; Create policy
    (map-set weather-policies
      { policy-id: policy-id }
      {
        policyholder: tx-sender,
        weather-type: weather-type,
        trigger-condition: trigger-condition,
        trigger-value: trigger-value,
        comparison-operator: comparison-operator,
        coverage-amount: coverage-amount,
        premium-amount: premium-amount,
        coverage-start: burn-block-height,
        coverage-end: coverage-end,
        location-lat: location-lat,
        location-lon: location-lon,
        status: "created",
        created-at: burn-block-height,
        premium-paid: false,
        settlement-triggered: false,
        payout-amount: u0
      }
    )
    
    ;; Initialize premium tracking
    (map-set policy-premiums
      { policy-id: policy-id }
      {
        total-premium: premium-amount,
        paid-amount: u0,
        payment-date: u0,
        payment-address: tx-sender
      }
    )
    
    ;; Update user policy index
    (map-set user-policies
      { user: tx-sender, policy-index: user-count }
      { policy-id: policy-id }
    )
    
    ;; Update user policy count
    (map-set user-policy-count
      { user: tx-sender }
      { count: (+ user-count u1) }
    )
    
    ;; Update global counters
    (var-set next-policy-id (+ policy-id u1))
    (var-set total-policies (+ (var-get total-policies) u1))
    
    (ok policy-id)
  )
)

(define-public (pay-premium (policy-id uint))
  (let
    (
      (policy-data (unwrap! (map-get? weather-policies { policy-id: policy-id }) err-not-found))
      (premium-data (unwrap! (map-get? policy-premiums { policy-id: policy-id }) err-not-found))
      (premium-amount (get premium-amount policy-data))
    )
    (asserts! (is-eq tx-sender (get policyholder policy-data)) err-unauthorized)
    (asserts! (not (get premium-paid policy-data)) err-already-exists)
    (asserts! (is-eq (get status policy-data) "created") err-policy-active)
    (asserts! (< burn-block-height (get coverage-end policy-data)) err-policy-expired)
    
    ;; In a real implementation, this would handle STX transfer for premium payment
    ;; For this demo, we'll just mark as paid
    
    ;; Update policy status
    (map-set weather-policies
      { policy-id: policy-id }
      (merge policy-data {
        premium-paid: true,
        status: "active"
      })
    )
    
    ;; Update premium payment record
    (map-set policy-premiums
      { policy-id: policy-id }
      (merge premium-data {
        paid-amount: premium-amount,
        payment-date: burn-block-height
      })
    )
    
    ;; Update global counters
    (var-set active-policies (+ (var-get active-policies) u1))
    (var-set total-premiums-collected (+ (var-get total-premiums-collected) premium-amount))
    
    (ok true)
  )
)

(define-public (cancel-policy (policy-id uint))
  (let
    (
      (policy-data (unwrap! (map-get? weather-policies { policy-id: policy-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get policyholder policy-data)) err-unauthorized)
    (asserts! (not (get settlement-triggered policy-data)) err-policy-active)
    (asserts! (or (is-eq (get status policy-data) "created") (is-eq (get status policy-data) "active")) err-policy-cancelled)
    
    ;; Update policy status
    (map-set weather-policies
      { policy-id: policy-id }
      (merge policy-data { status: "cancelled" })
    )
    
    ;; Update counters if policy was active
    (if (is-eq (get status policy-data) "active")
      (var-set active-policies (- (var-get active-policies) u1))
      true
    )
    
    (ok true)
  )
)

(define-public (update-policy-status (policy-id uint) (new-status (string-ascii 20)))
  (let
    (
      (policy-data (unwrap! (map-get? weather-policies { policy-id: policy-id }) err-not-found))
    )
    (asserts! (or (is-eq tx-sender contract-owner) (is-authorized-oracle tx-sender)) err-unauthorized)
    (asserts! (> (len new-status) u0) err-invalid-input)
    
    ;; Update policy status
    (ok (map-set weather-policies
      { policy-id: policy-id }
      (merge policy-data { status: new-status })
    ))
  )
)

(define-public (trigger-settlement (policy-id uint) (payout-amount uint))
  (let
    (
      (policy-data (unwrap! (map-get? weather-policies { policy-id: policy-id }) err-not-found))
    )
    (asserts! (or (is-eq tx-sender contract-owner) (is-authorized-oracle tx-sender)) err-unauthorized)
    (asserts! (is-eq (get status policy-data) "active") err-policy-cancelled)
    (asserts! (not (get settlement-triggered policy-data)) err-already-exists)
    (asserts! (<= payout-amount (get coverage-amount policy-data)) err-invalid-input)
    
    ;; Update policy with settlement information
    (map-set weather-policies
      { policy-id: policy-id }
      (merge policy-data {
        settlement-triggered: true,
        payout-amount: payout-amount,
        status: "settled"
      })
    )
    
    ;; Update global counters
    (var-set active-policies (- (var-get active-policies) u1))
    (var-set total-payouts-made (+ (var-get total-payouts-made) payout-amount))
    
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-policy-details (policy-id uint))
  (map-get? weather-policies { policy-id: policy-id })
)

(define-read-only (get-policy-premium (policy-id uint))
  (map-get? policy-premiums { policy-id: policy-id })
)

(define-read-only (get-user-policy-count (user principal))
  (default-to u0
    (get count
      (map-get? user-policy-count { user: user })
    )
  )
)

(define-read-only (get-user-policy (user principal) (policy-index uint))
  (match (map-get? user-policies { user: user, policy-index: policy-index })
    some-policy (map-get? weather-policies { policy-id: (get policy-id some-policy) })
    none
  )
)

(define-read-only (get-oracle-info (oracle principal))
  (map-get? authorized-oracles { oracle: oracle })
)

(define-read-only (get-total-policies)
  (var-get total-policies)
)

(define-read-only (get-active-policies)
  (var-get active-policies)
)

(define-read-only (get-total-premiums-collected)
  (var-get total-premiums-collected)
)

(define-read-only (get-total-payouts-made)
  (var-get total-payouts-made)
)

(define-read-only (get-next-policy-id)
  (var-get next-policy-id)
)

(define-read-only (is-oracle-authorized (oracle principal))
  (is-authorized-oracle oracle)
)

(define-read-only (get-contract-owner)
  contract-owner
)

