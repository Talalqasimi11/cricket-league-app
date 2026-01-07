-- Database Schema Dump

SET FOREIGN_KEY_CHECKS = 0;

-- Table structure for table `auth_failures`
DROP TABLE IF EXISTS `auth_failures`;
CREATE TABLE `auth_failures` (
  `id` int NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `failed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `resolved_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table structure for table `ball_by_ball`
DROP TABLE IF EXISTS `ball_by_ball`;
CREATE TABLE `ball_by_ball` (
  `id` int NOT NULL AUTO_INCREMENT,
  `match_id` int NOT NULL,
  `inning_id` int NOT NULL,
  `over_number` int NOT NULL,
  `ball_number` int NOT NULL,
  `sequence` int NOT NULL,
  `batsman_id` int NOT NULL,
  `bowler_id` int NOT NULL,
  `runs` int DEFAULT '0',
  `extras` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `wicket_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `out_player_id` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `match_id` (`match_id`),
  KEY `inning_id` (`inning_id`),
  KEY `batsman_id` (`batsman_id`),
  KEY `bowler_id` (`bowler_id`),
  CONSTRAINT `ball_by_ball_ibfk_1` FOREIGN KEY (`match_id`) REFERENCES `matches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ball_by_ball_ibfk_2` FOREIGN KEY (`inning_id`) REFERENCES `match_innings` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ball_by_ball_ibfk_3` FOREIGN KEY (`batsman_id`) REFERENCES `players` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ball_by_ball_ibfk_4` FOREIGN KEY (`bowler_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=721 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table structure for table `match_innings`
DROP TABLE IF EXISTS `match_innings`;
CREATE TABLE `match_innings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `match_id` int NOT NULL,
  `team_id` int NOT NULL,
  `batting_team_id` int NOT NULL,
  `bowling_team_id` int NOT NULL,
  `inning_number` int NOT NULL,
  `runs` int DEFAULT '0',
  `wickets` int DEFAULT '0',
  `overs` int DEFAULT '0',
  `overs_decimal` decimal(4,1) DEFAULT '0.0',
  `legal_balls` int DEFAULT '0',
  `status` enum('in_progress','completed') COLLATE utf8mb4_unicode_ci DEFAULT 'in_progress',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `current_striker_id` int DEFAULT NULL,
  `current_non_striker_id` int DEFAULT NULL,
  `current_bowler_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `match_id` (`match_id`),
  KEY `batting_team_id` (`batting_team_id`),
  KEY `bowling_team_id` (`bowling_team_id`),
  KEY `fk_mi_striker` (`current_striker_id`),
  KEY `fk_mi_non_striker` (`current_non_striker_id`),
  KEY `fk_mi_bowler` (`current_bowler_id`),
  CONSTRAINT `fk_mi_bowler` FOREIGN KEY (`current_bowler_id`) REFERENCES `players` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mi_non_striker` FOREIGN KEY (`current_non_striker_id`) REFERENCES `players` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mi_striker` FOREIGN KEY (`current_striker_id`) REFERENCES `players` (`id`) ON DELETE SET NULL,
  CONSTRAINT `match_innings_ibfk_1` FOREIGN KEY (`match_id`) REFERENCES `matches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `match_innings_ibfk_2` FOREIGN KEY (`batting_team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `match_innings_ibfk_3` FOREIGN KEY (`bowling_team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=140 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table structure for table `matches`
DROP TABLE IF EXISTS `matches`;
CREATE TABLE `matches` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tournament_id` int DEFAULT NULL,
  `team1_id` int NOT NULL,
  `team2_id` int NOT NULL,
  `match_datetime` datetime NOT NULL,
  `venue` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('not_started','live','completed','abandoned','scheduled') COLLATE utf8mb4_unicode_ci DEFAULT 'not_started',
  `overs` int DEFAULT '20',
  `winner_team_id` int DEFAULT NULL,
  `creator_id` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `target_score` int DEFAULT NULL,
  `team1_lineup` text COLLATE utf8mb4_unicode_ci,
  `team2_lineup` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  KEY `tournament_id` (`tournament_id`),
  KEY `team1_id` (`team1_id`),
  KEY `team2_id` (`team2_id`),
  KEY `winner_team_id` (`winner_team_id`),
  KEY `fk_matches_creator` (`creator_id`),
  CONSTRAINT `fk_matches_creator` FOREIGN KEY (`creator_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `matches_ibfk_1` FOREIGN KEY (`tournament_id`) REFERENCES `tournaments` (`id`) ON DELETE SET NULL,
  CONSTRAINT `matches_ibfk_2` FOREIGN KEY (`team1_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `matches_ibfk_3` FOREIGN KEY (`team2_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `matches_ibfk_4` FOREIGN KEY (`winner_team_id`) REFERENCES `teams` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=105 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table structure for table `password_resets`
DROP TABLE IF EXISTS `password_resets`;
CREATE TABLE `password_resets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `token_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `password_resets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table structure for table `player_match_stats`
DROP TABLE IF EXISTS `player_match_stats`;
CREATE TABLE `player_match_stats` (
  `id` int NOT NULL AUTO_INCREMENT,
  `match_id` int NOT NULL,
  `player_id` int NOT NULL,
  `runs` int DEFAULT '0',
  `balls_faced` int DEFAULT '0',
  `fours` int DEFAULT '0',
  `sixes` int DEFAULT '0',
  `is_out` tinyint(1) DEFAULT '0',
  `balls_bowled` int DEFAULT '0',
  `runs_conceded` int DEFAULT '0',
  `wickets` int DEFAULT '0',
  `maiden_overs` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_match_player` (`match_id`,`player_id`),
  KEY `player_id` (`player_id`),
  CONSTRAINT `player_match_stats_ibfk_1` FOREIGN KEY (`match_id`) REFERENCES `matches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `player_match_stats_ibfk_2` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1345 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table structure for table `players`
DROP TABLE IF EXISTS `players`;
CREATE TABLE `players` (
  `id` int NOT NULL AUTO_INCREMENT,
  `player_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `player_role` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `player_image_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `team_id` int NOT NULL,
  `is_temporary` tinyint(1) DEFAULT '0',
  `is_archived` tinyint(1) DEFAULT '0',
  `runs` int DEFAULT '0',
  `matches_played` int DEFAULT '0',
  `hundreds` int DEFAULT '0',
  `fifties` int DEFAULT '0',
  `batting_average` decimal(10,2) DEFAULT '0.00',
  `strike_rate` decimal(10,2) DEFAULT '0.00',
  `wickets` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `team_id` (`team_id`),
  CONSTRAINT `players_ibfk_1` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=66 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table structure for table `refresh_tokens`
DROP TABLE IF EXISTS `refresh_tokens`;
CREATE TABLE `refresh_tokens` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `token` varchar(512) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_revoked` tinyint(1) DEFAULT '0',
  `revoked_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `refresh_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table structure for table `team_tournament_summary`
DROP TABLE IF EXISTS `team_tournament_summary`;
CREATE TABLE `team_tournament_summary` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tournament_id` int NOT NULL,
  `team_id` int NOT NULL,
  `matches_played` int DEFAULT '0',
  `matches_won` int DEFAULT '0',
  `points` int DEFAULT '0',
  `nrr` decimal(10,3) DEFAULT '0.000',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_summary` (`tournament_id`,`team_id`),
  KEY `team_id` (`team_id`),
  CONSTRAINT `team_tournament_summary_ibfk_1` FOREIGN KEY (`tournament_id`) REFERENCES `tournaments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `team_tournament_summary_ibfk_2` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table structure for table `teams`
DROP TABLE IF EXISTS `teams`;
CREATE TABLE `teams` (
  `id` int NOT NULL AUTO_INCREMENT,
  `team_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `team_location` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `team_logo_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `owner_id` int NOT NULL,
  `captain_player_id` int DEFAULT NULL,
  `vice_captain_player_id` int DEFAULT NULL,
  `matches_played` int DEFAULT '0',
  `matches_won` int DEFAULT '0',
  `trophies` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `owner_id` (`owner_id`),
  KEY `captain_player_id` (`captain_player_id`),
  KEY `vice_captain_player_id` (`vice_captain_player_id`),
  CONSTRAINT `teams_captain_fk` FOREIGN KEY (`captain_player_id`) REFERENCES `players` (`id`) ON DELETE SET NULL,
  CONSTRAINT `teams_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `teams_vice_captain_fk` FOREIGN KEY (`vice_captain_player_id`) REFERENCES `players` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=77 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table structure for table `tournament_matches`
DROP TABLE IF EXISTS `tournament_matches`;
CREATE TABLE `tournament_matches` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tournament_id` int NOT NULL,
  `team1_id` int DEFAULT NULL,
  `team2_id` int DEFAULT NULL,
  `team1_tt_id` int DEFAULT NULL,
  `team2_tt_id` int DEFAULT NULL,
  `round` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `match_date` datetime DEFAULT NULL,
  `location` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('upcoming','live','finished') COLLATE utf8mb4_unicode_ci DEFAULT 'upcoming',
  `winner_id` int DEFAULT NULL,
  `parent_match_id` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `match_id` int DEFAULT NULL,
  `team1_lineup` text COLLATE utf8mb4_unicode_ci,
  `team2_lineup` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  KEY `tournament_id` (`tournament_id`),
  KEY `team1_id` (`team1_id`),
  KEY `team2_id` (`team2_id`),
  KEY `winner_id` (`winner_id`),
  CONSTRAINT `tournament_matches_ibfk_1` FOREIGN KEY (`tournament_id`) REFERENCES `tournaments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tournament_matches_ibfk_2` FOREIGN KEY (`team1_id`) REFERENCES `teams` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tournament_matches_ibfk_3` FOREIGN KEY (`team2_id`) REFERENCES `teams` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tournament_matches_ibfk_4` FOREIGN KEY (`winner_id`) REFERENCES `teams` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table structure for table `tournament_teams`
DROP TABLE IF EXISTS `tournament_teams`;
CREATE TABLE `tournament_teams` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tournament_id` int NOT NULL,
  `team_id` int NOT NULL,
  `temp_team_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `temp_team_location` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `tournament_id` (`tournament_id`),
  KEY `team_id` (`team_id`),
  CONSTRAINT `tournament_teams_ibfk_1` FOREIGN KEY (`tournament_id`) REFERENCES `tournaments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tournament_teams_ibfk_2` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=71 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table structure for table `tournaments`
DROP TABLE IF EXISTS `tournaments`;
CREATE TABLE `tournaments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tournament_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `start_date` datetime NOT NULL,
  `end_date` datetime DEFAULT NULL,
  `location` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('upcoming','live','completed','abandoned') COLLATE utf8mb4_unicode_ci DEFAULT 'upcoming',
  `overs` int DEFAULT '20',
  `created_by` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `winner_team_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `created_by` (`created_by`),
  KEY `fk_tourn_winner` (`winner_team_id`),
  CONSTRAINT `fk_tourn_winner` FOREIGN KEY (`winner_team_id`) REFERENCES `teams` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tournaments_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table structure for table `user_activity_logs`
DROP TABLE IF EXISTS `user_activity_logs`;
CREATE TABLE `user_activity_logs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `device_id` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `activity_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `metadata` json DEFAULT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `user_activity_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table structure for table `users`
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_admin` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `phone_number` (`phone_number`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
