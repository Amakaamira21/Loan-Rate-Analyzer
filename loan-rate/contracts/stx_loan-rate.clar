;; Mortgage Comparison Platform Smart Contract
;; A decentralized platform for comparing home loan options from multiple lenders

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-invalid-rate (err u104))
(define-constant err-lender-not-approved (err u105))
(define-constant err-offer-expired (err u106))
(define-constant err-application-exists (err u107))
(define-constant err-invalid-credit-score (err u108))
(define-constant err-insufficient-income (err u109))
(define-constant err-invalid-loan-term (err u110))

;; Data Variables
(define-data-var next-offer-id uint u1)
(define-data-var next-application-id uint u1)
(define-data-var platform-fee-rate uint u100) ;; 1% in basis points
(define-data-var platform-min-credit-score uint u580)
(define-data-var max-loan-to-value uint u9500) ;; 95% in basis points

;; Data Maps

;; Lender registration and information
(define-map lenders principal {
    name: (string-ascii 100),
    license-number: (string-ascii 50),
    is-approved: bool,
    reputation-score: uint,
    total-loans-issued: uint,
    average-rate: uint,
    registered-at: uint,
    contact-info: (string-ascii 200)
})

;; Mortgage offers from lenders
(define-map mortgage-offers uint {
    lender: principal,
    loan-type: (string-ascii 50), ;; "fixed", "variable", "fha", "va", etc.
    interest-rate: uint, ;; Annual rate in basis points
    loan-term: uint, ;; Term in months (e.g., 360 for 30 years)
    max-loan-amount: uint,
    min-loan-amount: uint,
    max-ltv-ratio: uint, ;; Loan-to-value ratio in basis points
    min-credit-score: uint,
    min-income: uint,
    points: uint, ;; Discount points in basis points
    origination-fee: uint, ;; Fee in basis points
    closing-cost-estimate: uint,
    apr: uint, ;; Annual percentage rate in basis points
    offer-valid-until: uint,
    is-active: bool,
    created-at: uint
})

;; User mortgage applications
(define-map mortgage-applications uint {
    borrower: principal,
    loan-amount: uint,
    property-value: uint,
    credit-score: uint,
    annual-income: uint,
    debt-to-income: uint, ;; Ratio in basis points
    loan-purpose: (string-ascii 50), ;; "purchase", "refinance", "cash-out"
    property-type: (string-ascii 50), ;; "single-family", "condo", "townhouse", etc.
    occupancy-type: (string-ascii 50), ;; "primary", "secondary", "investment"
    down-payment: uint,
    preferred-term: uint, ;; Preferred loan term in months
    status: (string-ascii 20), ;; "submitted", "approved", "rejected", "closed"
    created-at: uint,
    updated-at: uint
})

;; Application matches with offers
(define-map application-matches {application-id: uint, offer-id: uint} {
    match-score: uint, ;; Compatibility score (0-100)
    estimated-payment: uint,
    total-interest: uint,
    created-at: uint,
    lender-response: (optional (string-ascii 20)) ;; "interested", "pre-approved", "declined"
})

;; User profiles for borrowers
(define-map borrower-profiles principal {
    first-name: (string-ascii 50),
    last-name: (string-ascii 50),
    email: (string-ascii 100),
    phone: (string-ascii 20),
    applications-count: uint,
    verified: bool,
    created-at: uint
})

;; Platform statistics
(define-map platform-stats (string-ascii 20) uint)

;; Private Functions

;; Calculate monthly payment using approximation
(define-private (calculate-monthly-payment (principal uint) (annual-rate uint) (term-months uint))
    (let ((monthly-rate (/ annual-rate u120000))) ;; Convert annual rate to monthly decimal
        (if (is-eq monthly-rate u0)
            (/ principal term-months)
            (let ((rate-factor (+ u10000 monthly-rate))
                  (power-term (pow rate-factor term-months)))
                (/ (* principal monthly-rate power-term)
                   (- power-term u10000))))))

;; Calculate loan-to-value ratio
(define-private (calculate-ltv (loan-amount uint) (property-value uint))
    (if (is-eq property-value u0)
        u10000 ;; Return 100% if property value is 0 to prevent division by zero
        (/ (* loan-amount u10000) property-value)))

;; Calculate debt-to-income ratio
(define-private (calculate-dti (monthly-debt uint) (monthly-income uint))
    (if (is-eq monthly-income u0)
        u10000 ;; Return 100% if monthly income is 0 to prevent division by zero
        (/ (* monthly-debt u10000) monthly-income)))

;; Calculate match score between application and offer
(define-private (calculate-match-score (app-id uint) (offer-id uint))
    (match (map-get? mortgage-applications app-id)
        app (match (map-get? mortgage-offers offer-id)
            offer (let ((credit-match (if (>= (get credit-score app) (get min-credit-score offer)) u25 u0))
                        (income-match (if (>= (get annual-income app) (get min-income offer)) u25 u0))
                        (ltv-match (if (<= (calculate-ltv (get loan-amount app) (get property-value app))
                                          (get max-ltv-ratio offer)) u25 u0))
                        (amount-match (if (and (>= (get loan-amount app) (get min-loan-amount offer))
                                             (<= (get loan-amount app) (get max-loan-amount offer))) u25 u0)))
                    (+ credit-match income-match ltv-match amount-match))
            u0)
        u0))

;; Update platform statistics
(define-private (update-platform-stat (key (string-ascii 20)) (increment uint))
    (let ((current-value (default-to u0 (map-get? platform-stats key))))
        (map-set platform-stats key (+ current-value increment))))

;; Public Functions

;; Register as a lender
(define-public (register-lender 
    (name (string-ascii 100))
    (license-number (string-ascii 50))
    (contact-info (string-ascii 200)))
    (begin
        (map-set lenders tx-sender {
            name: name,
            license-number: license-number,
            is-approved: false,
            reputation-score: u100,
            total-loans-issued: u0,
            average-rate: u0,
            registered-at: stacks-block-height,
            contact-info: contact-info
        })
        (update-platform-stat "total-lenders" u1)
        (ok true)))

;; Approve lender (admin only)
(define-public (approve-lender (lender principal))
    (let ((lender-info (unwrap! (map-get? lenders lender) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set lenders lender (merge lender-info {is-approved: true}))
        (ok true)))

;; Create mortgage offer
(define-public (create-mortgage-offer
    (loan-type (string-ascii 50))
    (interest-rate uint)
    (loan-term uint)
    (max-loan-amount uint)
    (min-loan-amount uint)
    (max-ltv-ratio uint)
    (offer-min-credit-score uint)
    (offer-min-income uint)
    (points uint)
    (origination-fee uint)
    (closing-cost-estimate uint)
    (valid-days uint))
    (let ((offer-id (var-get next-offer-id))
          (lender-info (unwrap! (map-get? lenders tx-sender) err-not-found))
          (apr (+ interest-rate origination-fee points))) ;; Simplified APR calculation
        
        (asserts! (get is-approved lender-info) err-lender-not-approved)
        (asserts! (> interest-rate u0) err-invalid-rate)
        (asserts! (> loan-term u0) err-invalid-loan-term)
        (asserts! (> max-loan-amount min-loan-amount) err-invalid-amount)
        
        (map-set mortgage-offers offer-id {
            lender: tx-sender,
            loan-type: loan-type,
            interest-rate: interest-rate,
            loan-term: loan-term,
            max-loan-amount: max-loan-amount,
            min-loan-amount: min-loan-amount,
            max-ltv-ratio: max-ltv-ratio,
            min-credit-score: offer-min-credit-score,
            min-income: offer-min-income,
            points: points,
            origination-fee: origination-fee,
            closing-cost-estimate: closing-cost-estimate,
            apr: apr,
            offer-valid-until: (+ stacks-block-height (* valid-days u144)), ;; Assuming ~144 blocks per day
            is-active: true,
            created-at: stacks-block-height
        })
        
        (var-set next-offer-id (+ offer-id u1))
        (update-platform-stat "total-offers" u1)
        (ok offer-id)))

;; Submit mortgage application
(define-public (submit-mortgage-application
    (loan-amount uint)
    (property-value uint)
    (credit-score uint)
    (annual-income uint)
    (debt-to-income uint)
    (loan-purpose (string-ascii 50))
    (property-type (string-ascii 50))
    (occupancy-type (string-ascii 50))
    (down-payment uint)
    (preferred-term uint))
    (let ((app-id (var-get next-application-id)))
        
        (asserts! (> loan-amount u0) err-invalid-amount)
        (asserts! (> property-value u0) err-invalid-amount)
        (asserts! (and (>= credit-score u300) (<= credit-score u850)) err-invalid-credit-score)
        (asserts! (>= credit-score (var-get platform-min-credit-score)) err-invalid-credit-score)
        (asserts! (> annual-income u0) err-insufficient-income)
        (asserts! (<= (calculate-ltv loan-amount property-value) (var-get max-loan-to-value)) err-invalid-amount)
        
        (map-set mortgage-applications app-id {
            borrower: tx-sender,
            loan-amount: loan-amount,
            property-value: property-value,
            credit-score: credit-score,
            annual-income: annual-income,
            debt-to-income: debt-to-income,
            loan-purpose: loan-purpose,
            property-type: property-type,
            occupancy-type: occupancy-type,
            down-payment: down-payment,
            preferred-term: preferred-term,
            status: "submitted",
            created-at: stacks-block-height,
            updated-at: stacks-block-height
        })
        
        ;; Update borrower profile
        (let ((current-profile (default-to 
                {first-name: "", last-name: "", email: "", phone: "", 
                 applications-count: u0, verified: false, created-at: stacks-block-height}
                (map-get? borrower-profiles tx-sender))))
            (map-set borrower-profiles tx-sender 
                (merge current-profile {applications-count: (+ (get applications-count current-profile) u1)})))
        
        (var-set next-application-id (+ app-id u1))
        (update-platform-stat "total-applications" u1)
        (ok app-id)))

;; Match application with compatible offers
(define-public (find-matching-offers (app-id uint))
    (let ((app (unwrap! (map-get? mortgage-applications app-id) err-not-found)))
        (asserts! (is-eq (get borrower app) tx-sender) err-unauthorized)
        
        ;; This would typically iterate through all offers
        ;; For simplicity, we'll return success and let the front-end handle matching
        (ok "Matching process initiated - check get-application-matches")))

;; Lender responds to application match
(define-public (respond-to-application (app-id uint) (offer-id uint) (response (string-ascii 20)))
    (let ((offer (unwrap! (map-get? mortgage-offers offer-id) err-not-found))
          (match-key {application-id: app-id, offer-id: offer-id}))
        
        (asserts! (is-eq (get lender offer) tx-sender) err-unauthorized)
        (asserts! (is-some (map-get? application-matches match-key)) err-not-found)
        
        (let ((current-match (unwrap! (map-get? application-matches match-key) err-not-found)))
            (map-set application-matches match-key
                (merge current-match {lender-response: (some response)})))
        
        (ok true)))

;; Update offer status
(define-public (update-offer-status (offer-id uint) (is-active bool))
    (let ((offer (unwrap! (map-get? mortgage-offers offer-id) err-not-found)))
        (asserts! (is-eq (get lender offer) tx-sender) err-unauthorized)
        
        (map-set mortgage-offers offer-id (merge offer {is-active: is-active}))
        (ok true)))

;; Admin function to set platform parameters
(define-public (set-platform-parameters (min-credit uint) (max-ltv uint) (fee-rate uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set platform-min-credit-score min-credit)
        (var-set max-loan-to-value max-ltv)
        (var-set platform-fee-rate fee-rate)
        (ok true)))

;; Read-Only Functions

(define-read-only (get-lender-info (lender principal))
    (map-get? lenders lender))

(define-read-only (get-mortgage-offer (offer-id uint))
    (map-get? mortgage-offers offer-id))

(define-read-only (get-application (app-id uint))
    (map-get? mortgage-applications app-id))

(define-read-only (get-borrower-profile (borrower principal))
    (map-get? borrower-profiles borrower))

(define-read-only (get-application-match (app-id uint) (offer-id uint))
    (map-get? application-matches {application-id: app-id, offer-id: offer-id}))

(define-read-only (calculate-payment-estimate (loan-amount uint) (interest-rate uint) (term-months uint))
    (calculate-monthly-payment loan-amount interest-rate term-months))

(define-read-only (get-platform-statistics)
    {
        total-lenders: (default-to u0 (map-get? platform-stats "total-lenders")),
        total-offers: (default-to u0 (map-get? platform-stats "total-offers")),
        total-applications: (default-to u0 (map-get? platform-stats "total-applications")),
        min-credit-score: (var-get platform-min-credit-score),
        max-loan-to-value: (var-get max-loan-to-value),
        platform-fee-rate: (var-get platform-fee-rate)
    })

;; Search offers by criteria
(define-read-only (check-offer-eligibility 
    (offer-id uint) 
    (loan-amount uint) 
    (credit-score uint) 
    (annual-income uint)
    (ltv-ratio uint))
    (match (map-get? mortgage-offers offer-id)
        offer (ok {
            eligible: (and 
                (get is-active offer)
                (>= credit-score (get min-credit-score offer))
                (>= annual-income (get min-income offer))
                (<= ltv-ratio (get max-ltv-ratio offer))
                (>= loan-amount (get min-loan-amount offer))
                (<= loan-amount (get max-loan-amount offer))
                (< stacks-block-height (get offer-valid-until offer))),
            estimated-payment: (calculate-monthly-payment loan-amount (get interest-rate offer) (get loan-term offer)),
            total-closing-costs: (+ (get closing-cost-estimate offer) 
                                  (/ (* loan-amount (get origination-fee offer)) u10000))
        })
        (err "Offer not found")))

;; Get best offers for a loan amount and credit score
(define-read-only (get-competitive-rates (loan-amount uint) (credit-score uint))
    {
        message: "Use off-chain indexing service to get sorted offers by rate",
        suggestion: "Query offers with check-offer-eligibility for each offer-id"
    })

;; Calculate loan comparison metrics
(define-read-only (compare-loan-offers (offer-id-1 uint) (offer-id-2 uint) (loan-amount uint))
    (match (map-get? mortgage-offers offer-id-1)
        offer1 (match (map-get? mortgage-offers offer-id-2)
            offer2 (let ((payment1 (calculate-monthly-payment loan-amount (get interest-rate offer1) (get loan-term offer1)))
                         (payment2 (calculate-monthly-payment loan-amount (get interest-rate offer2) (get loan-term offer2))))
                (ok {
                    offer1-payment: payment1,
                    offer2-payment: payment2,
                    offer1-total-interest: (- (* payment1 (get loan-term offer1)) loan-amount),
                    offer2-total-interest: (- (* payment2 (get loan-term offer2)) loan-amount),
                    offer1-closing-costs: (get closing-cost-estimate offer1),
                    offer2-closing-costs: (get closing-cost-estimate offer2)
                }))
            (err "Offer 2 not found"))
        (err "Offer 1 not found")))

;; Emergency pause function
(define-public (emergency-pause)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        ;; Implementation for emergency pause
        (ok true)))