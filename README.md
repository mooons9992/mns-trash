# Trash Bin Scavenger - Advanced Loot System for QBCore

Trash Bin Scavenger is a comprehensive FiveM script that transforms ordinary trash bins and dumpsters into interactive loot sources. This feature-rich system adds depth to your roleplay server by allowing players to search for useful items while building a unique scavenging progression system.

## 🌟 Key Features

### Core Systems
- **Interactive Trash Searching**: Search through various trash bins and dumpsters across the city
- **Progression System**: Gain reputation as you find more items, level up your scavenging skills
- **Persistent Player Data**: Player reputation and collectibles save to database between server restarts
- **Customizable Animations**: Realistic searching animations with configurable duration

### Advanced Gameplay Features
- **Lockpick System**: Large dumpsters require lockpicks with configurable difficulty tiers
- **Location-Based Loot**: Different areas have unique loot pools (hospital, casino, etc.)
- **Trash Routes**: Start routes directly from trash bins with ox_target options
- **Collectibles System**: Find and collect special items to trade for valuable rewards
- **NPC Crafting Station**: Turn trash into useful items at the dedicated recycling center with NPC

### Environmental Effects
- **Time Impact**: Better loot during nighttime when fewer people are around
- **Weather Impact**: Rain makes trash wet and less valuable
- **Area Exhaustion**: Areas become less profitable when searched too often
- **NPC Reactions**: NPCs might notice your scavenging and react (including calling police)

### Technical Features
- **Multiple Framework Support**: Works with QBCore and OX libraries
- **Customizable Systems**: Configure which inventory, target, progress bar, and notification systems to use
- **Performance Optimized**: Minimal resource usage with efficient code structure
- **Developer Friendly**: Well-documented code for easy modifications

## 📋 Requirements
- QBCore Framework
- oxmysql
- ox_lib (recommended)
- ox_target (recommended) or qb-target
- ox_inventory (recommended) or qb-inventory

## 💾 Installation
1. Download the latest release
2. Extract to your resources folder
3. Import the SQL file (install.sql) into your database
4. Add `ensure mns-trash` to your server.cfg
5. Configure settings in config.lua to your liking

## ⚙️ Configuration
The configuration file allows you to customize nearly every aspect of the script:
- Choose which system components to use (inventory, target, progress, etc.)
- Define loot tables and chances
- Configure difficulty levels for different trash bins
- Set up location-specific loot pools
- Adjust NPC reaction settings
- Configure reputation rewards
- Set up collectible sets and crafting recipes

## 🗑️ Usage

### Trash Bin Searching
- Approach any trash bin or dumpster in the city
- Use the target system to interact with it (ox_target or qb-target)
- Some large dumpsters require lockpicks and will trigger a minigame
- Collect items, earn reputation, and occasionally find rare collectibles

### Trash Routes
- Start a route directly from any trash bin using the target menu
- Follow the GPS waypoints to complete the route
- Earn bonus rewards upon completion

### Crafting & Collectibles
- Visit the Recycling Center marked on the map to access:
   - Crafting station to turn trash into useful items
   - Collectibles trader to redeem bottle cap sets for rewards
- Interact with the NPC to access all crafting and collection features

## 🔄 Integration
Trash Bin Scavenger is designed to work seamlessly with:
- QBCore Framework
- OX Suite (ox_lib, ox_inventory, ox_target)
- Custom inventory/target systems via configuration

## 📊 Future Updates
- Job-specific loot pools
- Enhanced police integration
- Mobile app for tracking collectibles
- Achievements system
- Community events

---

Developed by Mooons  
Version: 2.0.0