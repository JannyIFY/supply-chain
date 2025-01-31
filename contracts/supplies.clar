;; SupplyChainTracker Smart Contract
;; Enables transparent tracking of item lifecycle and validations

(define-trait supply-chain-trait
  (
    (register-item (uint uint) (response bool uint))
    (update-item-phase (uint uint) (response bool uint))
    (get-item-timeline (uint) (response (list 10 {phase: uint, timestamp: uint}) uint))
    (add-validation (uint uint principal) (response bool uint))
    (verify-validation (uint uint) (response bool uint))
  )
)

;; Define item phase constants
(define-constant PHASE_MANUFACTURED u1)
(define-constant PHASE_SHIPPING u2)
(define-constant PHASE_RECEIVED u3)
(define-constant PHASE_INSPECTED u4)

;; Define validation type constants
(define-constant VALIDATION_ECO u1)
(define-constant VALIDATION_ETHICAL u2)
(define-constant VALIDATION_GREEN u3)
(define-constant VALIDATION_VERIFIED u4)

;; Error constants
(define-constant ERR_NOT_AUTHORIZED (err u1))
(define-constant ERR_INVALID_ITEM (err u2))
(define-constant ERR_PHASE_UPDATE_FAILED (err u3))
(define-constant ERR_INVALID_PHASE (err u4))
(define-constant ERR_INVALID_VALIDATION (err u5))
(define-constant ERR_VALIDATION_EXISTS (err u6))

;; Contract owner
(define-data-var contract-admin principal tx-sender)

;; Item tracking map
(define-map item-data 
  {item-id: uint} 
  {
    custodian: principal,
    current-phase: uint,
    timeline: (list 10 {phase: uint, timestamp: uint})
  }
)

;; Validation tracking map
(define-map item-validations
  {item-id: uint, validation-type: uint}
  {
    validator: principal,
    timestamp: uint,
    active: bool
  }
)

;; Approved validators
(define-map authorized-validators
  {validator: principal, validation-type: uint}
  {approved: bool}
)

;; Only contract admin can perform certain actions
(define-read-only (is-contract-admin (sender principal))
  (is-eq sender (var-get contract-admin))
)

;; Validate phase
(define-private (is-valid-phase (phase uint))
  (or 
    (is-eq phase PHASE_MANUFACTURED)
    (is-eq phase PHASE_SHIPPING)
    (is-eq phase PHASE_RECEIVED)
    (is-eq phase PHASE_INSPECTED)
  )
)

;; Validate validation type
(define-private (is-valid-validation-type (validation-type uint))
  (or
    (is-eq validation-type VALIDATION_ECO)
    (is-eq validation-type VALIDATION_ETHICAL)
    (is-eq validation-type VALIDATION_GREEN)
    (is-eq validation-type VALIDATION_VERIFIED)
  )
)

;; Validate item ID
(define-private (is-valid-item-id (item-id uint))
  (and (> item-id u0) (<= item-id u1000000))
)

;; Check if sender is approved validator
(define-private (is-authorized-validator (validator principal) (validation-type uint))
  (default-to 
    false
    (get approved (map-get? authorized-validators {validator: validator, validation-type: validation-type}))
  )
)

;; Register a new item
(define-public (register-item (item-id uint) (initial-phase uint))
  (begin
    (asserts! (is-valid-item-id item-id) ERR_INVALID_ITEM)
    (asserts! (is-valid-phase initial-phase) ERR_INVALID_PHASE)
    (asserts! (or (is-contract-admin tx-sender) (is-eq initial-phase PHASE_MANUFACTURED)) ERR_NOT_AUTHORIZED)
    
    (map-set item-data 
      {item-id: item-id}
      {
        custodian: tx-sender,
        current-phase: initial-phase,
        timeline: (list {phase: initial-phase, timestamp: block-height})
      }
    )
    (ok true)
  )
)

;; Update item phase
(define-public (update-item-phase (item-id uint) (new-phase uint))
  (let 
    (
      (item (unwrap! (map-get? item-data {item-id: item-id}) ERR_INVALID_ITEM))
    )
    (asserts! (is-valid-item-id item-id) ERR_INVALID_ITEM)
    (asserts! (is-valid-phase new-phase) ERR_INVALID_PHASE)
    (asserts! 
      (or 
        (is-contract-admin tx-sender)
        (is-eq (get custodian item) tx-sender)
      ) 
      ERR_NOT_AUTHORIZED
    )
    
    (map-set item-data 
      {item-id: item-id}
      (merge item 
        {
          current-phase: new-phase,
          timeline: (unwrap-panic 
            (as-max-len? 
              (append (get timeline item) {phase: new-phase, timestamp: block-height}) 
              u10
            )
          )
        }
      )
    )
    (ok true)
  )
)

;; Add validator
(define-public (add-validator (validator principal) (validation-type uint))
  (begin
    (asserts! (is-contract-admin tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (is-valid-validation-type validation-type) ERR_INVALID_VALIDATION)
    
    (map-set authorized-validators
      {validator: validator, validation-type: validation-type}
      {approved: true}
    )
    (ok true)
  )
)

;; Add validation to item
(define-public (add-validation (item-id uint) (validation-type uint))
  (begin
    (asserts! (is-valid-item-id item-id) ERR_INVALID_ITEM)
    (asserts! (is-valid-validation-type validation-type) ERR_INVALID_VALIDATION)
    (asserts! (is-authorized-validator tx-sender validation-type) ERR_NOT_AUTHORIZED)
    
    (asserts! 
      (is-none 
        (map-get? item-validations {item-id: item-id, validation-type: validation-type})
      )
      ERR_VALIDATION_EXISTS
    )
    
    (map-set item-validations
      {item-id: item-id, validation-type: validation-type}
      {
        validator: tx-sender,
        timestamp: block-height,
        active: true
      }
    )
    (ok true)
  )
)

;; Verify item validation
(define-read-only (verify-validation (item-id uint) (validation-type uint))
  (let
    (
      (validation (unwrap! 
        (map-get? item-validations {item-id: item-id, validation-type: validation-type})
        ERR_INVALID_VALIDATION
      ))
    )
    (ok (get active validation))
  )
)

;; Cancel validation
(define-public (cancel-validation (item-id uint) (validation-type uint))
  (begin
    (asserts! (is-valid-item-id item-id) ERR_INVALID_ITEM)
    (asserts! (is-valid-validation-type validation-type) ERR_INVALID_VALIDATION)
    
    (let
      (
        (validation (unwrap! 
          (map-get? item-validations {item-id: item-id, validation-type: validation-type})
          ERR_INVALID_VALIDATION
        ))
      )
      (asserts! 
        (or
          (is-contract-admin tx-sender)
          (is-eq (get validator validation) tx-sender)
        )
        ERR_NOT_AUTHORIZED
      )
      
      (map-set item-validations
        {item-id: item-id, validation-type: validation-type}
        (merge validation {active: false})
      )
      (ok true)
    )
  )
)

;; Get item timeline
(define-read-only (get-item-timeline (item-id uint))
  (let 
    (
      (item (unwrap! (map-get? item-data {item-id: item-id}) ERR_INVALID_ITEM))
    )
    (ok (get timeline item))
  )
)

;; Get current item phase
(define-read-only (get-item-phase (item-id uint))
  (let 
    (
      (item (unwrap! (map-get? item-data {item-id: item-id}) ERR_INVALID_ITEM))
    )
    (ok (get current-phase item))
  )
)

;; Get validation details
(define-read-only (get-validation-details (item-id uint) (validation-type uint))
  (ok (map-get? item-validations {item-id: item-id, validation-type: validation-type}))
)