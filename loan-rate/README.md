# Mortgage Comparison Platform Smart Contract

A decentralized mortgage comparison platform built on the Stacks blockchain that connects borrowers with multiple lenders, enabling transparent mortgage rate comparisons and streamlined application processes.

## Overview

This smart contract provides a trustless platform where:
- **Lenders** can register and create mortgage offers with competitive rates
- **Borrowers** can submit applications and compare offers from multiple lenders
- **Platform** facilitates matching between applications and offers based on eligibility criteria

## Key Features

### For Lenders
- **Registration System**: Secure lender registration with license verification
- **Offer Management**: Create and manage mortgage offers with flexible terms
- **Application Responses**: Review and respond to matched borrower applications
- **Reputation Tracking**: Built-in reputation scoring system

### For Borrowers
- **Application Submission**: Submit detailed mortgage applications
- **Automatic Matching**: Get matched with eligible offers based on creditworthiness
- **Rate Comparison**: Compare interest rates, terms, and closing costs
- **Payment Calculations**: Real-time monthly payment estimates

### Platform Features
- **Eligibility Verification**: Automated eligibility checking for loan-to-value ratios, credit scores, and income requirements
- **Match Scoring**: Intelligent matching algorithm between applications and offers
- **Statistics Tracking**: Platform-wide statistics and analytics
- **Admin Controls**: Platform parameter management and lender approval system

## Smart Contract Structure

### Data Maps
- `lenders`: Registered lender information and approval status
- `mortgage-offers`: Available mortgage offers from approved lenders
- `mortgage-applications`: Borrower applications and status
- `application-matches`: Matches between applications and offers
- `borrower-profiles`: User profiles and application history
- `platform-stats`: Platform-wide statistics and metrics

### Key Constants
- `platform-fee-rate`: Platform transaction fee (default: 1%)
- `platform-min-credit-score`: Minimum credit score requirement (default: 580)
- `max-loan-to-value`: Maximum loan-to-value ratio (default: 95%)

## Core Functions

### Lender Functions

#### `register-lender`
```clarity
(register-lender name license-number contact-info)
```
Register as a new lender on the platform.

#### `create-mortgage-offer`
```clarity
(create-mortgage-offer loan-type interest-rate loan-term max-loan-amount 
                      min-loan-amount max-ltv-ratio min-credit-score 
                      min-income points origination-fee closing-cost-estimate valid-days)
```
Create a new mortgage offer with specified terms and eligibility criteria.

#### `respond-to-application`
```clarity
(respond-to-application app-id offer-id response)
```
Respond to a matched borrower application with interest level.

### Borrower Functions

#### `submit-mortgage-application`
```clarity
(submit-mortgage-application loan-amount property-value credit-score annual-income 
                           debt-to-income loan-purpose property-type occupancy-type 
                           down-payment preferred-term)
```
Submit a mortgage application for lender review.

#### `find-matching-offers`
```clarity
(find-matching-offers app-id)
```
Initiate the matching process to find compatible offers.

### Read-Only Functions

#### `check-offer-eligibility`
```clarity
(check-offer-eligibility offer-id loan-amount credit-score annual-income ltv-ratio)
```
Check if a borrower is eligible for a specific offer and get payment estimates.

#### `compare-loan-offers`
```clarity
(compare-loan-offers offer-id-1 offer-id-2 loan-amount)
```
Compare two mortgage offers side-by-side with payment and cost analysis.

#### `calculate-payment-estimate`
```clarity
(calculate-payment-estimate loan-amount interest-rate term-months)
```
Calculate estimated monthly mortgage payments.

## Eligibility Criteria

### Borrower Requirements
- **Credit Score**: Minimum 580 (platform default)
- **Loan-to-Value**: Maximum 95%
- **Income Verification**: Minimum income requirements vary by offer
- **Debt-to-Income**: Calculated and tracked for lender review

### Offer Requirements
- **Interest Rate**: Must be greater than 0%
- **Loan Amount**: Valid range with minimum < maximum
- **Loan Term**: Must be greater than 0 months
- **Lender Status**: Must be approved by platform admin

## Usage Examples

### For Lenders

1. **Register as a lender**:
```clarity
(contract-call? .mortgage-platform register-lender 
  "ABC Mortgage Company" 
  "LIC123456" 
  "contact@abcmortgage.com")
```

2. **Create a mortgage offer**:
```clarity
(contract-call? .mortgage-platform create-mortgage-offer
  "fixed"        ;; loan type
  u375          ;; 3.75% interest rate (basis points)
  u360          ;; 30-year term
  u1000000      ;; $1M max loan
  u100000       ;; $100K min loan
  u9500         ;; 95% max LTV
  u620          ;; 620 min credit score
  u50000        ;; $50K min income
  u0            ;; 0 points
  u100          ;; 1% origination fee
  u5000         ;; $5K closing costs
  u30)          ;; Valid for 30 days
```

### For Borrowers

1. **Submit mortgage application**:
```clarity
(contract-call? .mortgage-platform submit-mortgage-application
  u400000       ;; $400K loan amount
  u500000       ;; $500K property value
  u720          ;; 720 credit score
  u80000        ;; $80K annual income
  u2800         ;; 28% debt-to-income
  "purchase"    ;; loan purpose
  "single-family" ;; property type
  "primary"     ;; occupancy
  u100000       ;; $100K down payment
  u360)         ;; 30-year preferred term
```

2. **Check offer eligibility**:
```clarity
(contract-call? .mortgage-platform check-offer-eligibility
  u1            ;; offer ID
  u400000       ;; loan amount
  u720          ;; credit score
  u80000        ;; annual income
  u8000)        ;; 80% LTV
```

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | err-owner-only | Function restricted to contract owner |
| u101 | err-not-found | Requested entity not found |
| u102 | err-unauthorized | User not authorized for this action |
| u103 | err-invalid-amount | Invalid loan or property amount |
| u104 | err-invalid-rate | Invalid interest rate |
| u105 | err-lender-not-approved | Lender not approved by platform |
| u106 | err-offer-expired | Mortgage offer has expired |
| u107 | err-application-exists | Application already exists |
| u108 | err-invalid-credit-score | Credit score outside valid range |
| u109 | err-insufficient-income | Income below minimum requirements |
| u110 | err-invalid-loan-term | Invalid loan term specified |

## Platform Administration

### Admin Functions
- `approve-lender`: Approve registered lenders
- `set-platform-parameters`: Update platform-wide settings
- `emergency-pause`: Emergency stop functionality

### Platform Statistics
The contract tracks:
- Total registered lenders
- Total active offers
- Total applications submitted
- Platform configuration parameters

## Security Considerations

1. **Lender Verification**: All lenders must be approved by platform admin before creating offers
2. **Data Validation**: Comprehensive input validation for all financial parameters
3. **Access Control**: Function-level access control for sensitive operations
4. **Rate Limits**: Built-in validation for reasonable interest rates and loan terms

## Development and Deployment

### Prerequisites
- Stacks blockchain testnet/mainnet access
- Clarity development environment
- Understanding of mortgage lending principles

### Testing
Thoroughly test all functions with various scenarios:
- Valid and invalid input parameters
- Edge cases for financial calculations
- Access control restrictions
- Matching algorithm accuracy

## Future Enhancements

- **Credit Score Integration**: Real-time credit score verification
- **Document Management**: IPFS integration for loan documents
- **Automated Underwriting**: ML-based risk assessment
- **Rate Lock Functionality**: Time-bound rate guarantees
- **Multi-currency Support**: Support for different currencies

## Contributing

This is a foundational smart contract that can be extended with additional features. When contributing:
1. Maintain existing error handling patterns
2. Add comprehensive input validation
3. Update documentation for new functions
4. Consider gas optimization for complex calculations

## License

This project is provided as-is for educational and development purposes. Ensure compliance with local financial regulations before deployment in production environments.

## Disclaimer

This smart contract is for demonstration purposes. Real-world mortgage lending involves complex regulatory requirements, credit assessments, and legal considerations that are not fully addressed in this implementation. Consult with legal and financial experts before using in production.