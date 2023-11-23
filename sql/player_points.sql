CREATE TABLE `player_points` (
  `account_id` int unsigned NOT NULL,
  `balance_loyal_point` int unsigned NOT NULL,
  `balance_donate_point` int unsigned NOT NULL,
  `all_player_points_reward` int DEFAULT '0',
  PRIMARY KEY (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;