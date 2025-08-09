# FlightGuard Pro: Decentralized Flight Delay Insurance Protocol

An autonomous blockchain-based insurance system that provides instant compensation for flight delays through oracle-verified flight data. Users purchase coverage with transparent pricing and receive automatic payouts when delays exceed predetermined thresholds.

## Features

- **Trustless Operation**: Fully decentralized with zero manual intervention
- **Real-time Claims Processing**: Automatic payouts based on oracle data
- **Transparent Pricing**: Clear premium calculation (0.1% of ticket value by default)
- **Instant Compensation**: Up to 300% of premium paid for qualifying delays
- **Oracle Integration**: Verified flight data from trusted external sources

## How It Works

1. **Purchase Insurance**: Users buy coverage by providing flight details and ticket cost
2. **Oracle Reports Delays**: Trusted oracles submit verified flight delay data
3. **Automatic Claims**: Smart contract automatically processes eligible claims
4. **Instant Payout**: Compensation is transferred directly to policyholders

## Protocol Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| Delay Threshold | 60 minutes | Minimum delay required for claims |
| Premium Rate | 0.1% | Percentage of ticket value charged as premium |
| Compensation Multiplier | 300% | Payout as percentage of premium paid |
| Maximum Coverage | 24 hours | Maximum delay duration covered |
| Premium Cap | 10% | Maximum premium as percentage of ticket value |
| Payout Cap | 10x | Maximum compensation multiplier |

## Smart Contract Functions

### User Functions

#### `purchase-flight-insurance`
Purchase insurance coverage for a specific flight.

**Parameters:**
- `flight-code` (string-utf8 15): Flight identifier (2-8 characters)
- `departure-timestamp` (uint): Scheduled departure time
- `ticket-cost` (uint): Cost of the airline ticket

**Returns:** Policy ID (uint)

**Example:**
```clarity
(purchase-flight-insurance "AA123" u1640995200 u50000)
```

#### `file-compensation-claim`
File a claim for compensation due to flight delay.

**Parameters:**
- `policy-id` (uint): Insurance policy identifier
- `flight-code` (string-utf8 15): Flight identifier

**Returns:** Success/error status

#### `cancel-coverage-policy`
Cancel an active insurance policy before flight departure.

**Parameters:**
- `policy-id` (uint): Insurance policy identifier  
- `flight-code` (string-utf8 15): Flight identifier

**Returns:** 50% premium refund

### Oracle Functions

#### `submit-flight-delay-report`
Submit verified flight delay data (Oracle only).

**Parameters:**
- `flight-code` (string-utf8 15): Flight identifier
- `actual-departure-timestamp` (uint): Actual departure time
- `delay-duration-minutes` (uint): Delay duration in minutes

### Administrative Functions

#### `update-oracle-address`
Update the trusted oracle address (Administrator only).

#### `configure-protocol-settings`
Update protocol parameters (Administrator only).

**Parameters:**
- `new-delay-threshold` (uint): Minimum delay for claims
- `new-premium-rate` (uint): Premium calculation rate
- `new-payout-multiplier` (uint): Compensation multiplier

### Read-Only Functions

#### `retrieve-policy-details`
Get details of a specific insurance policy.

#### `retrieve-flight-delay-data`
Get oracle-verified flight delay information.

#### `get-protocol-parameters`
Get current protocol configuration.

#### `calculate-insurance-premium`
Calculate premium for a given ticket value.

#### `verify-delay-claim-eligibility`
Check if a flight delay qualifies for compensation.

## Error Codes

| Code | Error | Description |
|------|--------|-------------|
| 100 | ERR-UNAUTHORIZED-ADMINISTRATOR | Not authorized as administrator |
| 101 | ERR-UNAUTHORIZED-ORACLE-SUBMISSION | Not authorized oracle |
| 102 | ERR-INVALID-PREMIUM-AMOUNT | Invalid premium calculation |
| 103 | ERR-POLICY-ALREADY-EXISTS | Policy already exists |
| 104 | ERR-POLICY-NOT-FOUND | Policy not found |
| 105 | ERR-POLICY-INACTIVE-OR-EXPIRED | Policy is inactive or expired |
| 106 | ERR-CLAIM-ALREADY-PROCESSED | Claim already processed |
| 107 | ERR-UNAUTHORIZED-POLICY-ACCESS | Not policy owner |
| 108 | ERR-INSUFFICIENT-DELAY-TIME | Delay below threshold |
| 109 | ERR-FLIGHT-DATA-UNVERIFIED | Flight data not verified |
| 110 | ERR-INVALID-DEPARTURE-TIME | Invalid departure time |
| 111 | ERR-INVALID-CONFIGURATION-PARAMETER | Invalid config parameter |
| 112 | ERR-MALFORMED-FLIGHT-CODE | Invalid flight code format |
| 113 | ERR-DELAY-DURATION-EXCEEDS-LIMIT | Delay exceeds maximum |
| 114 | ERR-INVALID-TIMESTAMP-VALUE | Invalid timestamp |

## Usage Examples

### Purchasing Insurance

```clarity
;; Purchase insurance for flight AA123 with $500 ticket
(purchase-flight-insurance "AA123" u1640995200 u50000000)
;; Premium: $5 (0.1% of $500)
;; Max payout: $15 (300% of premium)
```

### Filing a Claim

```clarity
;; File claim after oracle reports delay
(file-compensation-claim u1 "AA123")
;; Automatic payout if delay >= 60 minutes
```

## Security Features

- **Input Validation**: All inputs are validated for format and range
- **Authorization Checks**: Only authorized users can perform specific actions
- **Reentrancy Protection**: Safe transfer patterns prevent reentrancy attacks
- **Oracle Trust**: Single trusted oracle prevents manipulation
- **Time Validation**: Departure times must be in the future

## Deployment Requirements

1. **Stacks Blockchain**: Deploy on Stacks network
2. **Oracle Setup**: Configure trusted oracle address
3. **Initial Funding**: Contract needs STX for payouts
4. **Administrator**: Set protocol administrator address

## Integration

### For Airlines
- Integrate with booking systems
- Offer as add-on service
- Revenue sharing opportunities

### For Travel Platforms
- Embed in checkout flow
- Enhance customer experience
- Reduce support tickets

### For Developers
- Clear API interface
- Comprehensive error handling
- Event-driven architecture