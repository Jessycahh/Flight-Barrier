;; FlightGuard Pro: Decentralized Flight Delay Insurance Protocol Smart Contract
;; An autonomous blockchain-based insurance system that provides instant compensation
;; for flight delays through oracle-verified flight data. Users purchase coverage
;; with transparent pricing and receive automatic payouts when delays exceed
;; predetermined thresholds. Features trustless operation, real-time claim
;; processing, and zero manual intervention requirements.

;; GOVERNANCE & ADMINISTRATION

(define-data-var protocol-administrator principal tx-sender)
(define-data-var trusted-flight-oracle principal 'SP000000000000000000002Q6VF78)
(define-data-var delay-threshold-for-claims uint u60)
(define-data-var premium-calculation-rate uint u10) ;; 0.1% of ticket value
(define-data-var compensation-multiplier uint u300) ;; 300% of premium paid

;; SYSTEM CONSTRAINTS & LIMITS

(define-constant maximum-delay-coverage-hours u1440) ;; 24 hours maximum
(define-constant maximum-premium-percentage u1000) ;; 10% cap on premium rates
(define-constant maximum-payout-multiplier u1000) ;; 10x maximum compensation
(define-constant minimum-flight-identifier-length u2)
(define-constant maximum-flight-identifier-length u8)

;; ERROR DEFINITIONS

(define-constant ERR-UNAUTHORIZED-ADMINISTRATOR (err u100))
(define-constant ERR-UNAUTHORIZED-ORACLE-SUBMISSION (err u101))
(define-constant ERR-INVALID-PREMIUM-AMOUNT (err u102))
(define-constant ERR-POLICY-ALREADY-EXISTS (err u103))
(define-constant ERR-POLICY-NOT-FOUND (err u104))
(define-constant ERR-POLICY-INACTIVE-OR-EXPIRED (err u105))
(define-constant ERR-CLAIM-ALREADY-PROCESSED (err u106))
(define-constant ERR-UNAUTHORIZED-POLICY-ACCESS (err u107))
(define-constant ERR-INSUFFICIENT-DELAY-TIME (err u108))
(define-constant ERR-FLIGHT-DATA-UNVERIFIED (err u109))
(define-constant ERR-INVALID-DEPARTURE-TIME (err u110))
(define-constant ERR-INVALID-CONFIGURATION-PARAMETER (err u111))
(define-constant ERR-MALFORMED-FLIGHT-CODE (err u112))
(define-constant ERR-DELAY-DURATION-EXCEEDS-LIMIT (err u113))
(define-constant ERR-INVALID-TIMESTAMP-VALUE (err u114))

;; DATA STRUCTURES

;; Core insurance policy storage
(define-map insurance-coverage-registry
  { coverage-id: uint, flight-identifier: (string-utf8 15) }
  {
    policyholder-address: principal,
    scheduled-departure-timestamp: uint,
    premium-payment-amount: uint,
    maximum-claim-payout: uint,
    coverage-status-active: bool,
    compensation-claim-processed: bool
  }
)

;; Oracle-verified flight status records
(define-map flight-status-database
  { flight-identifier: (string-utf8 15), actual-departure-timestamp: uint }
  { recorded-delay-minutes: uint, oracle-data-verified: bool }
)

;; STATE MANAGEMENT

(define-data-var policy-identifier-counter uint u1)

;; INPUT VALIDATION HELPERS

(define-private (validate-oracle-address (oracle-principal principal))
  (and 
    (not (is-eq oracle-principal (var-get protocol-administrator)))
    (not (is-eq oracle-principal tx-sender)))
)

(define-private (validate-delay-threshold (threshold-minutes uint))
  (and (> threshold-minutes u0) 
       (<= threshold-minutes maximum-delay-coverage-hours))
)

(define-private (validate-premium-rate (rate-basis-points uint))
  (and (> rate-basis-points u0) 
       (<= rate-basis-points maximum-premium-percentage))
)

(define-private (validate-payout-multiplier (multiplier-percentage uint))
  (and (> multiplier-percentage u100) 
       (<= multiplier-percentage maximum-payout-multiplier))
)

(define-private (validate-flight-identifier (flight-code (string-utf8 15)))
  (and 
    (>= (len flight-code) minimum-flight-identifier-length)
    (<= (len flight-code) maximum-flight-identifier-length))
)

(define-private (validate-timestamp (timestamp-value uint))
  (> timestamp-value u0)
)

;; FINANCIAL CALCULATION FUNCTIONS

(define-read-only (calculate-insurance-premium (ticket-value uint))
  (/ (* ticket-value (var-get premium-calculation-rate)) u10000)
)

(define-read-only (calculate-maximum-compensation (premium-amount uint))
  (/ (* premium-amount (var-get compensation-multiplier)) u100)
)

;; ADMINISTRATIVE FUNCTIONS

(define-public (update-oracle-address (new-oracle-principal principal))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-administrator)) 
              ERR-UNAUTHORIZED-ADMINISTRATOR)
    (asserts! (validate-oracle-address new-oracle-principal) 
              ERR-INVALID-CONFIGURATION-PARAMETER)
    (ok (var-set trusted-flight-oracle new-oracle-principal))
  )
)

(define-public (configure-protocol-settings 
                (new-delay-threshold uint) 
                (new-premium-rate uint)
                (new-payout-multiplier uint))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-administrator)) 
              ERR-UNAUTHORIZED-ADMINISTRATOR)
    (asserts! (validate-delay-threshold new-delay-threshold) 
              ERR-INVALID-CONFIGURATION-PARAMETER)
    (asserts! (validate-premium-rate new-premium-rate) 
              ERR-INVALID-CONFIGURATION-PARAMETER)
    (asserts! (validate-payout-multiplier new-payout-multiplier) 
              ERR-INVALID-CONFIGURATION-PARAMETER)
    
    (var-set delay-threshold-for-claims new-delay-threshold)
    (var-set premium-calculation-rate new-premium-rate)
    (var-set compensation-multiplier new-payout-multiplier)
    (ok true)
  )
)

;; INSURANCE POLICY CREATION

(define-public (purchase-flight-insurance
                (flight-code (string-utf8 15))
                (departure-timestamp uint)
                (ticket-cost uint))
  (let (
    (calculated-premium (calculate-insurance-premium ticket-cost))
    (maximum-compensation (calculate-maximum-compensation calculated-premium))
    (new-policy-id (var-get policy-identifier-counter))
  )
    ;; Input validation checks
    (asserts! (validate-flight-identifier flight-code) 
              ERR-MALFORMED-FLIGHT-CODE)
    (asserts! (validate-timestamp departure-timestamp) 
              ERR-INVALID-TIMESTAMP-VALUE)
    (asserts! (> calculated-premium u0) 
              ERR-INVALID-PREMIUM-AMOUNT)
    (asserts! (> departure-timestamp block-height) 
              ERR-INVALID-DEPARTURE-TIME)
    
    ;; Prevent duplicate policy creation
    (asserts! (is-none (map-get? insurance-coverage-registry 
                                { coverage-id: new-policy-id, 
                                  flight-identifier: flight-code })) 
              ERR-POLICY-ALREADY-EXISTS)
    
    ;; Process premium payment
    (try! (stx-transfer? calculated-premium tx-sender (as-contract tx-sender)))
    
    ;; Create and store insurance policy
    (map-set insurance-coverage-registry
      { coverage-id: new-policy-id, flight-identifier: flight-code }
      {
        policyholder-address: tx-sender,
        scheduled-departure-timestamp: departure-timestamp,
        premium-payment-amount: calculated-premium,
        maximum-claim-payout: maximum-compensation,
        coverage-status-active: true,
        compensation-claim-processed: false
      }
    )
    
    ;; Update policy counter
    (var-set policy-identifier-counter (+ new-policy-id u1))
    
    (ok new-policy-id)
  )
)

;; ORACLE DATA MANAGEMENT

(define-public (submit-flight-delay-report
                (flight-code (string-utf8 15))
                (actual-departure-timestamp uint)
                (delay-duration-minutes uint))
  (begin
    ;; Authorization and validation checks
    (asserts! (is-eq tx-sender (var-get trusted-flight-oracle)) 
              ERR-UNAUTHORIZED-ORACLE-SUBMISSION)
    (asserts! (validate-flight-identifier flight-code) 
              ERR-MALFORMED-FLIGHT-CODE)
    (asserts! (validate-timestamp actual-departure-timestamp) 
              ERR-INVALID-TIMESTAMP-VALUE)
    (asserts! (<= delay-duration-minutes maximum-delay-coverage-hours) 
              ERR-DELAY-DURATION-EXCEEDS-LIMIT)
    
    ;; Record verified flight delay data
    (map-set flight-status-database
      { flight-identifier: flight-code, actual-departure-timestamp: actual-departure-timestamp }
      { recorded-delay-minutes: delay-duration-minutes, oracle-data-verified: true }
    )
    
    (ok true)
  )
)

;; CLAIM VERIFICATION LOGIC

(define-read-only (verify-delay-claim-eligibility
                    (flight-code (string-utf8 15))
                    (departure-timestamp uint))
  (if (and 
       (validate-flight-identifier flight-code)
       (validate-timestamp departure-timestamp))
    (match (map-get? flight-status-database 
                    { flight-identifier: flight-code, 
                      actual-departure-timestamp: departure-timestamp })
      delay-data (and
                  (get oracle-data-verified delay-data)
                  (>= (get recorded-delay-minutes delay-data) 
                      (var-get delay-threshold-for-claims)))
      false
    )
    false
  )
)

;; CLAIM PROCESSING

(define-public (file-compensation-claim
                (policy-id uint)
                (flight-code (string-utf8 15)))
  (let (
    (policy-lookup-key { coverage-id: policy-id, 
                        flight-identifier: flight-code })
  )
    ;; Validate flight code format
    (asserts! (validate-flight-identifier flight-code) 
              ERR-MALFORMED-FLIGHT-CODE)
    
    ;; Process compensation claim
    (match (map-get? insurance-coverage-registry policy-lookup-key)
      policy-record 
        (let (
          (scheduled-departure (get scheduled-departure-timestamp policy-record))
        )
          ;; Policy status validation
          (asserts! (get coverage-status-active policy-record) 
                    ERR-POLICY-INACTIVE-OR-EXPIRED)
          (asserts! (not (get compensation-claim-processed policy-record)) 
                    ERR-CLAIM-ALREADY-PROCESSED)
          (asserts! (validate-timestamp scheduled-departure) 
                    ERR-INVALID-TIMESTAMP-VALUE)
          
          ;; Verify policyholder authorization
          (asserts! (is-eq tx-sender (get policyholder-address policy-record)) 
                    ERR-UNAUTHORIZED-POLICY-ACCESS)
          
          ;; Validate delay claim eligibility
          (asserts! (verify-delay-claim-eligibility flight-code scheduled-departure) 
                    ERR-INSUFFICIENT-DELAY-TIME)
          
          ;; Update claim status
          (map-set insurance-coverage-registry
            policy-lookup-key
            (merge policy-record { compensation-claim-processed: true })
          )
          
          ;; Execute compensation payout
          (as-contract (stx-transfer? (get maximum-claim-payout policy-record) 
                                    tx-sender 
                                    (get policyholder-address policy-record)))
        )
      ERR-POLICY-NOT-FOUND
    )
  )
)

;; POLICY MANAGEMENT

(define-public (cancel-coverage-policy
                (policy-id uint)
                (flight-code (string-utf8 15)))
  (let (
    (policy-lookup-key { coverage-id: policy-id, 
                        flight-identifier: flight-code })
  )
    ;; Validate flight identifier
    (asserts! (validate-flight-identifier flight-code) 
              ERR-MALFORMED-FLIGHT-CODE)
    
    ;; Execute policy cancellation
    (match (map-get? insurance-coverage-registry policy-lookup-key)
      policy-record
        (begin
          ;; Policy status checks
          (asserts! (get coverage-status-active policy-record) 
                    ERR-POLICY-INACTIVE-OR-EXPIRED)
          (asserts! (not (get compensation-claim-processed policy-record)) 
                    ERR-CLAIM-ALREADY-PROCESSED)
          
          ;; Verify policyholder authorization
          (asserts! (is-eq tx-sender (get policyholder-address policy-record)) 
                    ERR-UNAUTHORIZED-POLICY-ACCESS)
          
          ;; Ensure flight departure is future-dated
          (asserts! (> (get scheduled-departure-timestamp policy-record) block-height) 
                    ERR-INVALID-DEPARTURE-TIME)
          
          ;; Deactivate insurance policy
          (map-set insurance-coverage-registry
            policy-lookup-key
            (merge policy-record { coverage-status-active: false })
          )
          
          ;; Process partial premium refund (50%)
          (as-contract (stx-transfer? (/ (get premium-payment-amount policy-record) u2) 
                                    tx-sender 
                                    (get policyholder-address policy-record)))
        )
      ERR-POLICY-NOT-FOUND
    )
  )
)

;; PUBLIC DATA ACCESS FUNCTIONS

(define-read-only (retrieve-policy-details
                    (policy-id uint)
                    (flight-code (string-utf8 15)))
  (if (validate-flight-identifier flight-code)
    (map-get? insurance-coverage-registry 
             { coverage-id: policy-id, 
               flight-identifier: flight-code })
    none
  )
)

(define-read-only (retrieve-flight-delay-data
                    (flight-code (string-utf8 15))
                    (departure-timestamp uint))
  (if (and
       (validate-flight-identifier flight-code)
       (validate-timestamp departure-timestamp))
    (map-get? flight-status-database 
             { flight-identifier: flight-code, 
               actual-departure-timestamp: departure-timestamp })
    none
  )
)

(define-read-only (get-protocol-parameters)
  {
    protocol-owner: (var-get protocol-administrator),
    authorized-oracle: (var-get trusted-flight-oracle),
    minimum-delay-for-payout: (var-get delay-threshold-for-claims),
    premium-rate-basis-points: (var-get premium-calculation-rate),
    compensation-multiplier-percent: (var-get compensation-multiplier)
  }
)