-- --------------------------------------------------------
-- Create tables for mns-trash
-- --------------------------------------------------------

-- Create trash_reputation table to store player reputation levels
CREATE TABLE IF NOT EXISTS `trash_reputation` (
  `citizenid` varchar(50) NOT NULL,
  `reputation` int(11) NOT NULL DEFAULT 0,
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create trash_collectibles table to store player collectible items
CREATE TABLE IF NOT EXISTS `trash_collectibles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `collectible_id` varchar(50) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 1,
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `player_collectible_index` (`citizenid`, `collectible_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create trash_area_exhaustion table to store area exhaustion data
CREATE TABLE IF NOT EXISTS `trash_area_exhaustion` (
  `area_key` varchar(50) NOT NULL,
  `searches` int(11) NOT NULL DEFAULT 0,
  `last_reset` int(11) NOT NULL,
  PRIMARY KEY (`area_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create trash_stats table for global statistics
CREATE TABLE IF NOT EXISTS `trash_stats` (
  `total_searches` int(11) NOT NULL DEFAULT 0,
  `total_items_found` int(11) NOT NULL DEFAULT 0,
  `rare_items_found` int(11) NOT NULL DEFAULT 0,
  `collectibles_found` int(11) NOT NULL DEFAULT 0,
  `routes_completed` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert initial stats record
INSERT INTO `trash_stats` (`total_searches`, `total_items_found`, `rare_items_found`, `collectibles_found`, `routes_completed`) 
VALUES (0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE `total_searches` = `total_searches`;