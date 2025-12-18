-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: localhost    Database: cricket_league
-- ------------------------------------------------------
-- Server version	8.0.43

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `auth_failures`
--

DROP TABLE IF EXISTS `auth_failures`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_failures` (
  `id` int NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ip_address` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `resolved_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_auth_failures_phone` (`phone_number`),
  KEY `idx_auth_failures_time` (`failed_at`),
  KEY `idx_auth_failures_phone_time` (`phone_number`,`failed_at`),
  KEY `idx_auth_failures_phone_ip_time` (`phone_number`,`ip_address`,`failed_at`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ball_by_ball`
--

DROP TABLE IF EXISTS `ball_by_ball`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ball_by_ball` (
  `id` int NOT NULL AUTO_INCREMENT,
  `match_id` int NOT NULL,
  `inning_id` int NOT NULL,
  `over_number` int NOT NULL,
  `ball_number` int NOT NULL,
  `batsman_id` int NOT NULL,
  `bowler_id` int NOT NULL,
  `runs` int DEFAULT '0',
  `extras` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `wicket_type` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `out_player_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ball_pos` (`inning_id`,`over_number`,`ball_number`),
  KEY `fk_ball_batsman` (`batsman_id`),
  KEY `fk_ball_out_player` (`out_player_id`),
  KEY `idx_ball_by_ball_inning` (`inning_id`),
  KEY `idx_ball_by_ball_position` (`inning_id`,`over_number`,`ball_number`),
  KEY `idx_ball_by_ball_bowler` (`bowler_id`),
  KEY `idx_ball_match_inning` (`match_id`,`inning_id`),
  CONSTRAINT `fk_ball_batsman` FOREIGN KEY (`batsman_id`) REFERENCES `players` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ball_bowler` FOREIGN KEY (`bowler_id`) REFERENCES `players` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ball_innings` FOREIGN KEY (`inning_id`) REFERENCES `match_innings` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ball_match` FOREIGN KEY (`match_id`) REFERENCES `matches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ball_out_player` FOREIGN KEY (`out_player_id`) REFERENCES `players` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `feedback`
--

DROP TABLE IF EXISTS `feedback`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `feedback` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `message` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `contact` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_feedback_user` (`user_id`),
  CONSTRAINT `fk_feedback_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `match_innings`
--

DROP TABLE IF EXISTS `match_innings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `match_innings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `match_id` int NOT NULL,
  `team_id` int NOT NULL,
  `inning_number` int NOT NULL DEFAULT '1',
  `overs` int NOT NULL DEFAULT '0',
  `status` enum('in_progress','completed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'in_progress',
  `batting_team_id` int DEFAULT NULL,
  `bowling_team_id` int DEFAULT NULL,
  `runs` int DEFAULT '0',
  `wickets` int DEFAULT '0',
  `overs_decimal` decimal(4,1) DEFAULT '0.0',
  PRIMARY KEY (`id`),
  KEY `fk_innings_team` (`team_id`),
  KEY `idx_match_innings_match` (`match_id`),
  KEY `idx_match_innings_batting` (`batting_team_id`),
  KEY `idx_match_innings_bowling` (`bowling_team_id`),
  CONSTRAINT `fk_innings_batting` FOREIGN KEY (`batting_team_id`) REFERENCES `teams` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_innings_bowling` FOREIGN KEY (`bowling_team_id`) REFERENCES `teams` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_innings_match` FOREIGN KEY (`match_id`) REFERENCES `matches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_innings_team` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `matches`
--

DROP TABLE IF EXISTS `matches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matches` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tournament_id` int DEFAULT NULL,
  `team1_id` int NOT NULL,
  `team2_id` int NOT NULL,
  `match_datetime` datetime NOT NULL,
  `venue` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('not_started','live','completed','abandoned') COLLATE utf8mb4_unicode_ci DEFAULT 'not_started',
  `overs` int NOT NULL DEFAULT '20',
  `winner_team_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_match_winner` (`winner_team_id`),
  KEY `idx_matches_team1_id` (`team1_id`),
  KEY `idx_matches_team2_id` (`team2_id`),
  KEY `idx_matches_tournament` (`tournament_id`),
  KEY `idx_matches_status` (`status`),
  CONSTRAINT `fk_match_team1` FOREIGN KEY (`team1_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_match_team2` FOREIGN KEY (`team2_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_match_tournament` FOREIGN KEY (`tournament_id`) REFERENCES `tournaments` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_match_winner` FOREIGN KEY (`winner_team_id`) REFERENCES `teams` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `password_resets`
--

DROP TABLE IF EXISTS `password_resets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `password_resets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `token_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` datetime NOT NULL,
  `used_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_password_resets_user` (`user_id`),
  KEY `idx_password_resets_active` (`user_id`,`used_at`,`expires_at`),
  CONSTRAINT `fk_password_resets_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `player_match_stats`
--

DROP TABLE IF EXISTS `player_match_stats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `player_match_stats` (
  `id` int NOT NULL AUTO_INCREMENT,
  `player_id` int NOT NULL,
  `match_id` int NOT NULL,
  `runs` int DEFAULT '0',
  `balls_faced` int DEFAULT '0',
  `balls_bowled` int DEFAULT '0',
  `runs_conceded` int DEFAULT '0',
  `wickets` int DEFAULT '0',
  `fours` int DEFAULT '0',
  `sixes` int DEFAULT '0',
  `overs_bowled` decimal(4,1) DEFAULT '0.0',
  `catches` int DEFAULT '0',
  `stumpings` int DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_player_match_stats_player` (`player_id`),
  KEY `idx_player_match_stats_match` (`match_id`),
  CONSTRAINT `fk_stats_match` FOREIGN KEY (`match_id`) REFERENCES `matches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_stats_player` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `players`
--

DROP TABLE IF EXISTS `players`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `players` (
  `id` int NOT NULL AUTO_INCREMENT,
  `team_id` int NOT NULL,
  `player_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `player_role` enum('Batsman','Bowler','All-rounder','Wicket-keeper') COLLATE utf8mb4_unicode_ci NOT NULL,
  `player_image_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `runs` int DEFAULT '0',
  `matches_played` int DEFAULT '0',
  `hundreds` int DEFAULT '0',
  `fifties` int DEFAULT '0',
  `batting_average` decimal(5,2) DEFAULT '0.00',
  `strike_rate` decimal(5,2) DEFAULT '0.00',
  `wickets` int DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_players_team` (`team_id`),
  CONSTRAINT `fk_player_team` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `refresh_tokens`
--

DROP TABLE IF EXISTS `refresh_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `refresh_tokens` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `token` varchar(512) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_revoked` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `revoked_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_refresh_token` (`token`),
  KEY `idx_refresh_user` (`user_id`),
  KEY `idx_refresh_tokens_user_revoked` (`user_id`,`is_revoked`),
  KEY `idx_refresh_tokens_token` (`token`),
  CONSTRAINT `fk_refresh_tokens_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `teams`
--

DROP TABLE IF EXISTS `teams`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teams` (
  `id` int NOT NULL AUTO_INCREMENT,
  `owner_id` int NOT NULL,
  `team_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `team_location` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `team_logo_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `matches_played` int DEFAULT '0',
  `matches_won` int DEFAULT '0',
  `trophies` int DEFAULT '0',
  `captain_player_id` int DEFAULT NULL,
  `vice_captain_player_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_teams_captain_player_id` (`captain_player_id`),
  KEY `idx_teams_name` (`team_name`),
  KEY `idx_teams_location` (`team_location`),
  KEY `idx_teams_name_location` (`team_name`,`team_location`),
  KEY `idx_teams_owner` (`owner_id`),
  CONSTRAINT `fk_team_owner` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `teams_captain_vice_distinct` CHECK (((`captain_player_id` is null) or (`vice_captain_player_id` is null) or (`captain_player_id` <> `vice_captain_player_id`)))
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tournament_matches`
--

DROP TABLE IF EXISTS `tournament_matches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tournament_matches` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tournament_id` int NOT NULL,
  `team1_id` int DEFAULT NULL,
  `team2_id` int DEFAULT NULL,
  `team1_tt_id` int DEFAULT NULL,
  `team2_tt_id` int DEFAULT NULL,
  `round` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'round_1',
  `match_date` datetime DEFAULT NULL,
  `location` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('upcoming','live','finished') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'upcoming',
  `winner_id` int DEFAULT NULL,
  `parent_match_id` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_tournament_match_winner` (`winner_id`),
  KEY `idx_tournament_matches_tournament` (`tournament_id`),
  KEY `idx_tournament_matches_team1_id` (`team1_id`),
  KEY `idx_tournament_matches_team2_id` (`team2_id`),
  KEY `idx_tournament_matches_team1_tt_id` (`team1_tt_id`),
  KEY `idx_tournament_matches_team2_tt_id` (`team2_tt_id`),
  KEY `idx_tournament_matches_parent_match_id` (`parent_match_id`),
  KEY `idx_tourn_matches_tourn_id` (`tournament_id`),
  CONSTRAINT `fk_tournament_match_parent` FOREIGN KEY (`parent_match_id`) REFERENCES `tournament_matches` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tournament_match_team1` FOREIGN KEY (`team1_id`) REFERENCES `teams` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tournament_match_team1_tt` FOREIGN KEY (`team1_tt_id`) REFERENCES `tournament_teams` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tournament_match_team2` FOREIGN KEY (`team2_id`) REFERENCES `teams` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tournament_match_team2_tt` FOREIGN KEY (`team2_tt_id`) REFERENCES `tournament_teams` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tournament_match_tournament` FOREIGN KEY (`tournament_id`) REFERENCES `tournaments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tournament_match_winner` FOREIGN KEY (`winner_id`) REFERENCES `teams` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tournament_teams`
--

DROP TABLE IF EXISTS `tournament_teams`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tournament_teams` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tournament_id` int NOT NULL,
  `team_id` int DEFAULT NULL,
  `temp_team_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `temp_team_location` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `registration_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tt_registered` (`tournament_id`,`team_id`),
  UNIQUE KEY `uq_tt_temp` (`tournament_id`,`temp_team_name`,`temp_team_location`),
  KEY `idx_tournament_teams_team_id` (`team_id`),
  KEY `idx_tournament_teams_tournament` (`tournament_id`),
  CONSTRAINT `fk_tournament_team_team` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tournament_team_tournament` FOREIGN KEY (`tournament_id`) REFERENCES `tournaments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tournaments`
--

DROP TABLE IF EXISTS `tournaments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tournaments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tournament_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `location` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `start_date` date NOT NULL,
  `status` enum('upcoming','not_started','live','completed','abandoned') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'not_started',
  `created_by` int NOT NULL,
  `overs` int DEFAULT '20' COMMENT 'Number of overs per innings',
  `end_date` date DEFAULT NULL COMMENT 'Expected tournament end date',
  PRIMARY KEY (`id`),
  KEY `idx_tournaments_created_by` (`created_by`),
  KEY `idx_tournaments_name` (`tournament_name`),
  KEY `idx_tournaments_status` (`status`),
  KEY `idx_tournaments_end_date` (`end_date`),
  KEY `idx_tournaments_overs` (`overs`),
  CONSTRAINT `fk_tournament_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_admin` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `phone_number` (`phone_number`),
  UNIQUE KEY `uq_users_phone` (`phone_number`),
  KEY `idx_users_phone` (`phone_number`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-11-23 20:58:04
