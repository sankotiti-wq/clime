# Clime - Weather Derivatives Platform 🗂️

A decentralized smart contract system for weather-based insurance and derivatives on the Stacks blockchain.

## Overview

Clime is an innovative weather derivatives platform that enables automated insurance payouts based on verified weather data. Built on the Stacks blockchain using Clarity smart contracts, it provides transparent, tamper-proof weather-based financial instruments for agriculture, tourism, energy, and other weather-sensitive industries.

## Features

### ☁️ Weather Insurance
- Create customizable weather insurance policies
- Automatic payouts triggered by weather conditions
- Support for multiple weather parameters (temperature, precipitation, wind, humidity)
- Flexible coverage periods and geographic zones
- Premium calculation based on risk assessment

### 📊 Derivatives Trading
- Weather derivatives for hedging weather risk
- Temperature-based contracts (heating/cooling degree days)
- Precipitation derivatives for agricultural protection
- Seasonal weather futures and options
- Transparent price discovery mechanisms

### 🌡️ Weather Data Integration
- Oracle-based weather data verification
- Multiple data source aggregation for accuracy
- Historical weather pattern analysis
- Real-time weather monitoring and alerts
- Dispute resolution for data discrepancies

### 💰 Automated Settlements
- Smart contract-driven payout mechanisms
- Instant settlements when conditions are met
- Multi-tier payout structures
- Transparent calculation methods
- Minimal counterparty risk

## Architecture

The system consists of two main smart contracts:

1. **Weather Policy Manager** (`weather-policy.clar`)
   - Creates and manages weather insurance policies
   - Handles premium payments and policy registration
   - Manages policy terms and conditions
   - Tracks active policies and their status

2. **Settlement Engine** (`settlement-engine.clar`)
   - Processes weather data and triggers payouts
   - Manages oracle data feeds and verification
   - Handles dispute resolution and data validation
   - Executes automatic settlements based on conditions

## Smart Contract Functions

### Weather Policy Manager
- `create-policy`: Create new weather insurance policy
- `pay-premium`: Submit premium payment for policy
- `get-policy-details`: Retrieve policy information
- `update-policy-status`: Modify policy status
- `cancel-policy`: Cancel active policy (with conditions)

### Settlement Engine
- `submit-weather-data`: Oracle submission of weather data
- `verify-data`: Validate weather data from multiple sources
- `calculate-payout`: Determine payout amount based on conditions
- `execute-settlement`: Process automatic payout
- `dispute-data`: Challenge weather data accuracy
- `resolve-dispute`: Admin resolution of data disputes

## Usage

### For Policyholders
1. Create weather insurance policy with specific conditions
2. Pay premium to activate coverage
3. Monitor weather conditions during coverage period
4. Receive automatic payouts when trigger conditions are met
5. Access transparent settlement history and calculations

### For Weather Data Providers (Oracles)
1. Register as authorized weather data provider
2. Submit verified weather data at regular intervals
3. Participate in data validation and consensus mechanisms
4. Earn rewards for accurate and timely data submission
5. Handle dispute resolution when data is challenged

### For Risk Managers
1. Create custom weather derivatives contracts
2. Set complex weather-based trigger conditions
3. Manage portfolio risk across multiple weather events
4. Access historical data and risk analytics
5. Hedge weather exposure through derivative instruments

## Weather Parameters Supported

### Temperature-Based Coverage
- Daily average, minimum, maximum temperatures
- Heating Degree Days (HDD) and Cooling Degree Days (CDD)
- Growing Degree Days (GDD) for agriculture
- Extreme temperature events and duration

### Precipitation Coverage
- Daily, weekly, monthly rainfall amounts
- Drought conditions and duration
- Excessive rainfall and flood risk
- Snow accumulation and snowpack levels

### Wind and Storm Protection
- Wind speed measurements and sustained periods
- Hurricane and severe storm events
- Hail occurrence and intensity
- Tornado activity in specified regions

### Specialized Weather Events
- Frost dates and duration for agriculture
- Heat waves and cold snaps
- Humidity levels for specific industries
- Solar radiation for renewable energy

## Development

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks blockchain development environment

### Setup
```bash
# Clone the repository
git clone <repository-url>
cd clime

# Install dependencies
npm install

# Run contract syntax check
clarinet check

# Run tests
npm test
```

### Testing
The project includes comprehensive test suites for both contracts:
- Unit tests for policy creation and management
- Weather data validation and settlement testing
- Edge case testing for extreme weather events
- Integration tests for oracle data flow

## Deployment

### Testnet Deployment
```bash
# Deploy to Stacks testnet
clarinet deploy --testnet
```

### Mainnet Deployment
```bash
# Deploy to Stacks mainnet
clarinet deploy --mainnet
```

## Security

- Weather data verification through multiple oracle sources
- Time-locked settlement periods to prevent manipulation
- Multi-signature controls for administrative functions
- Transparent payout calculations and settlement history
- Dispute resolution mechanisms for data accuracy

## Use Cases

### Agriculture
- Crop insurance for weather-related losses
- Seasonal weather hedging for farmers
- Livestock protection from extreme temperatures
- Irrigation planning based on precipitation forecasts

### Energy Sector
- Temperature-based energy demand forecasting
- Solar and wind energy production insurance
- Utility revenue protection from weather variations
- Peak demand management and capacity planning

### Tourism and Hospitality
- Event cancellation insurance due to weather
- Seasonal tourism revenue protection
- Ski resort snow guarantee programs
- Beach resort weather insurance

### Construction and Infrastructure
- Weather delay insurance for projects
- Concrete curing protection from temperature extremes
- Road construction weather risk management
- Infrastructure maintenance scheduling

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and add tests
4. Run `clarinet check` to verify syntax
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions, issues, or feature requests, please open an issue on GitHub or contact the development team.

---

Built with ❤️ using Clarity and the Stacks blockchain for transparent weather-based financial instruments.
