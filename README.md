# SupplyChainTracker Smart Contract

A Clarity smart contract for transparent supply chain management on the Stacks blockchain. This contract enables tracking of items through their lifecycle while managing various types of validations and certifications.

## Features

The SupplyChainTracker provides comprehensive supply chain management capabilities including:

- Item lifecycle tracking through multiple phases
- Validation system with authorized validators
- Complete timeline tracking for each item
- Role-based access control
- Support for multiple validation types (Eco, Ethical, Green, Verified)

## Contract Structure

### Item Phases

Items in the supply chain can exist in the following phases:

- PHASE_MANUFACTURED (u1): Item has been produced
- PHASE_SHIPPING (u2): Item is in transit
- PHASE_RECEIVED (u3): Item has been delivered
- PHASE_INSPECTED (u4): Item has passed quality inspection

### Validation Types

The contract supports four types of validations:

- VALIDATION_ECO (u1): Environmental certification
- VALIDATION_ETHICAL (u2): Fair trade/ethical practices certification
- VALIDATION_GREEN (u3): Sustainability certification
- VALIDATION_VERIFIED (u4): Quality assurance certification

## Core Functions

### Item Management

```clarity
(define-public (register-item (item-id uint) (initial-phase uint)))
(define-public (update-item-phase (item-id uint) (new-phase uint)))
(define-read-only (get-item-phase (item-id uint)))
(define-read-only (get-item-timeline (item-id uint)))
```

### Validation Management

```clarity
(define-public (add-validator (validator principal) (validation-type uint)))
(define-public (add-validation (item-id uint) (validation-type uint)))
(define-public (cancel-validation (item-id uint) (validation-type uint)))
(define-read-only (verify-validation (item-id uint) (validation-type uint)))
```

## Error Handling

The contract includes comprehensive error handling with the following error codes:

- ERR_NOT_AUTHORIZED (u1): Caller lacks necessary permissions
- ERR_INVALID_ITEM (u2): Invalid item ID
- ERR_PHASE_UPDATE_FAILED (u3): Phase update operation failed
- ERR_INVALID_PHASE (u4): Invalid phase specified
- ERR_INVALID_VALIDATION (u5): Invalid validation type
- ERR_VALIDATION_EXISTS (u6): Validation already exists for item

## Usage Examples

### Registering a New Item

```clarity
;; Register a new item with ID 1 in the MANUFACTURED phase
(contract-call? .supply-chain-tracker register-item u1 PHASE_MANUFACTURED)
```

### Updating Item Phase

```clarity
;; Update item 1 to SHIPPING phase
(contract-call? .supply-chain-tracker update-item-phase u1 PHASE_SHIPPING)
```

### Adding a Validation

```clarity
;; Add ECO validation to item 1
(contract-call? .supply-chain-tracker add-validation u1 VALIDATION_ECO)
```

## Security Considerations

- Only the contract administrator can add new validators
- Item phase updates require custodian or administrator privileges
- Validations can only be added by authorized validators
- Validations can only be cancelled by the original validator or administrator
- Item IDs are limited to the range 1-1,000,000

## Storage

The contract uses three main maps for data storage:

1. `item-data`: Stores item details and timeline
2. `item-validations`: Tracks validations for each item
3. `authorized-validators`: Maintains list of approved validators

## Integration Guide

### Prerequisites

- Stacks blockchain node
- Clarity smart contract deployment tools
- Required permissions for contract interaction

### Deployment Steps

1. Deploy the contract to the Stacks blockchain
2. Set up initial administrator account
3. Add authorized validators
4. Begin registering items and tracking their lifecycle

## Contributing

When contributing to this contract:

1. Ensure all new functions include proper error handling
2. Add appropriate access controls for sensitive operations
3. Maintain the existing validation patterns
4. Update documentation for any new features or changes
