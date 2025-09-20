;; Settlement Engine Contract
;; Processes weather data, validates conditions, and executes automatic settlements

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-not-found (err u201))
(define-constant err-already-exists (err u202))
(define-constant err-invalid-input (err u203))
(define-constant err-unauthorized (err u204))
(define-constant err-invalid-data (err u205))
(define-constant err-data-too-old (err u206))
(define-constant err-insufficient-consensus (err u207))
(define-constant err-settlement-window-closed (err u208))
(define-constant err-dispute-period-active (err u209))

;; Data structures
(define-map weather-data
  { location-key: (string-ascii 50), date: uint }
  {
    temperature-avg: int,
    temperature-min: int,
    temperature-max: int,
    precipitation: uint,
    humidity: uint,
    wind-speed: uint,
    pressure: uint,
    submitted-by: principal,
    submission-time: uint,
    verified: bool,
    verification-count: uint,
    dispute-count: uint
  }
)

(define-map weather-data-consensus
  { location-key: (string-ascii 50), date: uint, oracle: principal }
  {
    temperature-avg: int,
    temperature-min: int,
    temperature-max: int,
    precipitation: uint,
    humidity: uint,
    wind-speed: uint,
    pressure: uint,
    submission-time: uint,
    weight: uint
  }
)

(define-map settlement-calculations
  { policy-id: uint }
  {
    weather-conditions-met: bool,
    trigger-value-actual: int,
    payout-percentage: uint,
    calculated-payout: uint,
    calculation-date: uint,
    calculated-by: principal,
    settlement-status: (string-ascii 20),
    weather-data-location: (string-ascii 50),
    weather-data-date: uint
  }
)

(define-map dispute-records
  { dispute-id: uint }
  {
    policy-id: uint,
    disputer: principal,
    dispute-type: (string-ascii 50),
    dispute-reason: (string-ascii 200),
    disputed-data-location: (string-ascii 50),
    disputed-data-date: uint,
    dispute-date: uint,
    resolution-status: (string-ascii 20),
    resolution-date: uint,
    resolved-by: principal
  }
)

(define-map oracle-performance
  { oracle: principal }
  {
    total-submissions: uint,
    verified-submissions: uint,
    disputed-submissions: uint,
    accuracy-score: uint,
    last-submission: uint,
    reputation-points: uint
  }
)

(define-map location-weather-history
  { location-key: (string-ascii 50), parameter: (string-ascii 20) }
  {
    last-30-day-avg: int,
    last-7-day-avg: int,
    historical-min: int,
    historical-max: int,
    data-points: uint,
    last-updated: uint
  }
)

(define-data-var next-dispute-id uint u1)
(define-data-var total-settlements uint u0)
(define-data-var total-disputes uint u0)
(define-data-var consensus-threshold uint u3)
(define-data-var data-validity-period uint u144) ;; ~24 hours in blocks
(define-data-var dispute-period uint u1008) ;; ~7 days in blocks

;; Weather data submission functions
(define-public (submit-weather-data
  (location-key (string-ascii 50))
  (date uint)
  (temperature-avg int)
  (temperature-min int)
  (temperature-max int)
  (precipitation uint)
  (humidity uint)
  (wind-speed uint)
  (pressure uint)
  )
  (let
    (
      (oracle-perf (get-oracle-performance tx-sender))
    )
    (asserts! (> (len location-key) u0) err-invalid-input)
    (asserts! (> date u0) err-invalid-input)
    (asserts! (<= temperature-min temperature-avg) err-invalid-data)
    (asserts! (<= temperature-avg temperature-max) err-invalid-data)
    (asserts! (<= humidity u100) err-invalid-data)
    
    ;; Check if oracle is authorized (this would reference the policy contract in a real implementation)
    
    ;; Submit consensus data
    (map-set weather-data-consensus
      { location-key: location-key, date: date, oracle: tx-sender }
      {
        temperature-avg: temperature-avg,
        temperature-min: temperature-min,
        temperature-max: temperature-max,
        precipitation: precipitation,
        humidity: humidity,
        wind-speed: wind-speed,
        pressure: pressure,
        submission-time: burn-block-height,
        weight: (get reputation-points oracle-perf)
      }
    )
    
    ;; Update oracle performance
    (map-set oracle-performance
      { oracle: tx-sender }
      {
        total-submissions: (+ (get total-submissions oracle-perf) u1),
        verified-submissions: (get verified-submissions oracle-perf),
        disputed-submissions: (get disputed-submissions oracle-perf),
        accuracy-score: (get accuracy-score oracle-perf),
        last-submission: burn-block-height,
        reputation-points: (get reputation-points oracle-perf)
      }
    )
    
    ;; Check if we have enough consensus to create verified weather data
    (let
      (
        (consensus-result (attempt-consensus-verification location-key date))
      )
      (ok true)
    )
  )
)

(define-private (attempt-consensus-verification (location-key (string-ascii 50)) (date uint))
  (let
    (
      (consensus-count (count-consensus-submissions location-key date))
    )
    (if (>= consensus-count (var-get consensus-threshold))
      (begin
        (create-verified-weather-data location-key date)
        (ok true)
      )
      (ok false)
    )
  )
)

(define-private (count-consensus-submissions (location-key (string-ascii 50)) (date uint))
  ;; This would count actual submissions in a real implementation
  ;; For simplicity, we'll return a default value
  u3
)

(define-private (create-verified-weather-data (location-key (string-ascii 50)) (date uint))
  ;; This would aggregate consensus data from multiple oracles
  ;; For simplicity, we'll create a basic verified record
  (map-set weather-data
    { location-key: location-key, date: date }
    {
      temperature-avg: 20, ;; This would be calculated from consensus
      temperature-min: 15,
      temperature-max: 25,
      precipitation: u0,
      humidity: u65,
      wind-speed: u10,
      pressure: u1013,
      submitted-by: tx-sender,
      submission-time: burn-block-height,
      verified: true,
      verification-count: (var-get consensus-threshold),
      dispute-count: u0
    }
  )
)

;; Settlement calculation functions
(define-public (calculate-settlement (policy-id uint) (location-key (string-ascii 50)) (weather-date uint))
  (let
    (
      (weather-info (unwrap! (map-get? weather-data { location-key: location-key, date: weather-date }) err-not-found))
    )
    (asserts! (or (is-eq tx-sender contract-owner)) err-unauthorized)
    (asserts! (get verified weather-info) err-invalid-data)
    (asserts! (< (- burn-block-height (get submission-time weather-info)) (var-get data-validity-period)) err-data-too-old)
    
    ;; In a real implementation, this would fetch policy details and evaluate conditions
    ;; For demo purposes, we'll create a basic calculation
    (let
      (
        (conditions-met true) ;; This would be calculated based on actual weather vs policy triggers
        (payout-percentage u75) ;; This would be calculated based on severity
        (calculated-payout u750000) ;; This would be percentage of coverage amount
      )
      
      ;; Store settlement calculation
      (map-set settlement-calculations
        { policy-id: policy-id }
        {
          weather-conditions-met: conditions-met,
          trigger-value-actual: (get temperature-avg weather-info),
          payout-percentage: payout-percentage,
          calculated-payout: calculated-payout,
          calculation-date: burn-block-height,
          calculated-by: tx-sender,
          settlement-status: "calculated",
          weather-data-location: location-key,
          weather-data-date: weather-date
        }
      )
      
      (ok {
        conditions-met: conditions-met,
        payout-amount: calculated-payout
      })
    )
  )
)

(define-public (execute-settlement (policy-id uint))
  (let
    (
      (settlement-data (unwrap! (map-get? settlement-calculations { policy-id: policy-id }) err-not-found))
    )
    (asserts! (or (is-eq tx-sender contract-owner)) err-unauthorized)
    (asserts! (get weather-conditions-met settlement-data) err-invalid-input)
    (asserts! (is-eq (get settlement-status settlement-data) "calculated") err-already-exists)
    
    ;; Check dispute period has passed
    (asserts! (> (- burn-block-height (get calculation-date settlement-data)) (var-get dispute-period)) err-dispute-period-active)
    
    ;; Update settlement status
    (map-set settlement-calculations
      { policy-id: policy-id }
      (merge settlement-data { settlement-status: "executed" })
    )
    
    ;; Update global counters
    (var-set total-settlements (+ (var-get total-settlements) u1))
    
    ;; In a real implementation, this would trigger payout to the policyholder
    
    (ok (get calculated-payout settlement-data))
  )
)

;; Dispute functions
(define-public (dispute-weather-data 
  (policy-id uint)
  (dispute-type (string-ascii 50))
  (dispute-reason (string-ascii 200))
  (disputed-location (string-ascii 50))
  (disputed-date uint)
  )
  (let
    (
      (dispute-id (var-get next-dispute-id))
    )
    (asserts! (> (len dispute-type) u0) err-invalid-input)
    (asserts! (> (len dispute-reason) u0) err-invalid-input)
    (asserts! (> (len disputed-location) u0) err-invalid-input)
    
    ;; Create dispute record
    (map-set dispute-records
      { dispute-id: dispute-id }
      {
        policy-id: policy-id,
        disputer: tx-sender,
        dispute-type: dispute-type,
        dispute-reason: dispute-reason,
        disputed-data-location: disputed-location,
        disputed-data-date: disputed-date,
        dispute-date: burn-block-height,
        resolution-status: "open",
        resolution-date: u0,
        resolved-by: contract-owner
      }
    )
    
    ;; Update counters
    (var-set next-dispute-id (+ dispute-id u1))
    (var-set total-disputes (+ (var-get total-disputes) u1))
    
    (ok dispute-id)
  )
)

(define-public (resolve-dispute (dispute-id uint) (resolution (string-ascii 20)))
  (let
    (
      (dispute-data (unwrap! (map-get? dispute-records { dispute-id: dispute-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-eq (get resolution-status dispute-data) "open") err-already-exists)
    (asserts! (> (len resolution) u0) err-invalid-input)
    
    ;; Update dispute resolution
    (map-set dispute-records
      { dispute-id: dispute-id }
      (merge dispute-data {
        resolution-status: resolution,
        resolution-date: burn-block-height,
        resolved-by: tx-sender
      })
    )
    
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-weather-data (location-key (string-ascii 50)) (date uint))
  (map-get? weather-data { location-key: location-key, date: date })
)

(define-read-only (get-settlement-calculation (policy-id uint))
  (map-get? settlement-calculations { policy-id: policy-id })
)

(define-read-only (get-dispute-details (dispute-id uint))
  (map-get? dispute-records { dispute-id: dispute-id })
)

(define-read-only (get-oracle-performance (oracle principal))
  (default-to
    {
      total-submissions: u0,
      verified-submissions: u0,
      disputed-submissions: u0,
      accuracy-score: u100,
      last-submission: u0,
      reputation-points: u100
    }
    (map-get? oracle-performance { oracle: oracle })
  )
)

(define-read-only (get-consensus-data (location-key (string-ascii 50)) (date uint) (oracle principal))
  (map-get? weather-data-consensus { location-key: location-key, date: date, oracle: oracle })
)

(define-read-only (get-total-settlements)
  (var-get total-settlements)
)

(define-read-only (get-total-disputes)
  (var-get total-disputes)
)

(define-read-only (get-consensus-threshold)
  (var-get consensus-threshold)
)

(define-read-only (get-data-validity-period)
  (var-get data-validity-period)
)

(define-read-only (get-dispute-period)
  (var-get dispute-period)
)

(define-read-only (get-next-dispute-id)
  (var-get next-dispute-id)
)

(define-read-only (get-contract-owner)
  contract-owner
)

