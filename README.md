# 🏃‍♀️ Fitness Challenge Reward System

A blockchain-based fitness tracking system that rewards verified physical activities with tokens. Connect your wearables, join challenges, and earn rewards for staying active! 💪

## ✨ Features

- 🎯 **Create Custom Challenges**: Set up fitness challenges with custom rewards
- 👥 **Join Community Challenges**: Participate in challenges created by others  
- 📊 **Track Activities**: Log workouts with duration and calories burned
- ✅ **Activity Verification**: Secure verification system for genuine activities
- 🪙 **Token Rewards**: Earn FITNESS tokens for verified activities
- 📈 **Progress Tracking**: Monitor your fitness journey and total rewards

## 🚀 Getting Started

### Prerequisites
- Clarinet CLI installed
- Stacks wallet for testing

### Installation

1. Clone the repository
```bash
git clone https://github.com/lurayakubu2/Fitness-Challenge-Reward-System.git
cd Fitness-Challenge-Reward-System
```

2. Install dependencies
```bash
npm install
```

3. Run tests
```bash
clarinet test
```

## 🎮 Usage

### 1. Register as a User 👤
```clarity
(contract-call? .Fitness-Challenge-Reward-System register-user)
```
- Registers you in the system
- Automatically mints 1000 FITNESS tokens as welcome bonus

### 2. Create a Challenge 🎯
```clarity
(contract-call? .Fitness-Challenge-Reward-System create-challenge 
    "30-Day Running Challenge" 
    "Run at least 30 minutes daily for 30 days" 
    u50  ;; 50 tokens per activity
    u100 ;; max 100 participants
    u4320) ;; 30 days in blocks
```

### 3. Join a Challenge 🤝
```clarity
(contract-call? .Fitness-Challenge-Reward-System join-challenge u1)
```

### 4. Log Your Activity 📝
```clarity
(contract-call? .Fitness-Challenge-Reward-System log-activity 
    u1           ;; challenge ID
    "running"    ;; activity type
    u45          ;; 45 minutes
    u400)        ;; 400 calories burned
```

### 5. Verify Activities (Challenge Creator/Owner) ✅
```clarity
(contract-call? .Fitness-Challenge-Reward-System verify-activity u1)
```

### 6. Claim Your Rewards 🎁
```clarity
(contract-call? .Fitness-Challenge-Reward-System claim-reward u1)
```

## 📚 Contract Functions

### Public Functions

| Function | Description |
|----------|-------------|
| `register-user` | Register as a new user |
| `create-challenge` | Create a new fitness challenge |
| `join-challenge` | Join an existing challenge |
| `log-activity` | Record a fitness activity |
| `verify-activity` | Verify an activity (creators/owners only) |
| `claim-reward` | Claim tokens for verified activities |
| `end-challenge` | End a challenge (creator only) |

### Read-Only Functions

| Function | Description |
|----------|-------------|
| `get-user-data` | Get user profile information |
| `get-challenge` | Get challenge details |
| `get-activity` | Get activity information |
| `get-user-balance` | Check token balance |
| `is-participant` | Check if user is in a challenge |

## 🛠️ Development

### Running Tests
```bash
clarinet test
```

### Deploying Locally
```bash
clarinet integrate
```

### Check Contract
```bash
clarinet check
```

## 🏗️ Architecture

The smart contract uses three main data structures:

- **Users**: Store registration status, activity counts, and rewards
- **Challenges**: Define fitness challenges with participants and rewards  
- **Activities**: Track individual workout sessions and verification status

## 🔒 Security Features

- Only challenge creators can verify activities in their challenges
- Users can only claim rewards for their own verified activities
- Contract owner has admin verification privileges
- Challenge participation limits prevent overflow attacks

## 🪙 Token Economy

- **Welcome Bonus**: 1000 FITNESS tokens upon registration
- **Activity Rewards**: Tokens earned per verified activity (set by challenge creator)
- **Token Supply**: Unlimited (minted as rewards are claimed)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🎯 Roadmap

- [ ] Integration with popular fitness wearables
- [ ] Advanced activity verification using oracles
- [ ] NFT achievements for milestones
- [ ] Social features and leaderboards
- [ ] Cross-chain compatibility

---

Built with ❤️ on Stacks blockchain
