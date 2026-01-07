-- MySQL dump 10.13  Distrib 8.0.44, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: cricket_league
-- ------------------------------------------------------
-- Server version	8.0.44

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
  `phone_number` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ip_address` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `failed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `resolved_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_failures`
--

LOCK TABLES `auth_failures` WRITE;
/*!40000 ALTER TABLE `auth_failures` DISABLE KEYS */;
INSERT INTO `auth_failures` VALUES (1,'+91234567890',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36','2025-12-18 14:02:20',NULL),(2,'+91234567890',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36','2025-12-18 14:02:26',NULL),(3,'+91234567890',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36','2025-12-18 14:02:33',NULL),(4,'+91234567890',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36','2025-12-19 15:13:56',NULL),(5,'+1234567890',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36','2025-12-19 15:14:10',NULL),(6,'+91234567890',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36','2025-12-19 15:14:13',NULL),(7,'92321456789',NULL,'192.168.10.20','Dart/3.9 (dart:io)','2025-12-22 15:48:51',NULL),(8,'9231123456789',NULL,'192.168.10.20','Dart/3.9 (dart:io)','2025-12-22 15:48:59',NULL),(9,'1234567890',NULL,'127.0.0.1',NULL,'2025-12-22 18:00:05',NULL),(10,'+1234567890',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36','2025-12-23 13:54:45',NULL),(11,'+1234567890',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36','2025-12-23 15:09:40',NULL),(12,NULL,'admin@example.com','127.0.0.1','node','2025-12-27 08:56:46','2026-01-06 16:58:47'),(13,'923123456789',NULL,'192.168.10.20','Dart/3.9 (dart:io)','2025-12-30 09:48:33','2025-12-30 09:49:01'),(14,NULL,'admin@example.com','127.0.0.1','node','2026-01-06 14:23:01','2026-01-06 16:58:47'),(15,NULL,'admin@example.com','127.0.0.1','node','2026-01-06 15:45:43','2026-01-06 16:58:47'),(16,NULL,'admin@example.com','127.0.0.1','node','2026-01-06 15:46:50','2026-01-06 16:58:47'),(17,NULL,'admin@example.com','127.0.0.1','node','2026-01-06 15:48:49','2026-01-06 16:58:47'),(18,NULL,'admin@example.com','127.0.0.1','node','2026-01-06 15:55:23','2026-01-06 16:58:47');
/*!40000 ALTER TABLE `auth_failures` ENABLE KEYS */;
UNLOCK TABLES;

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
  `sequence` int NOT NULL,
  `batsman_id` int NOT NULL,
  `bowler_id` int NOT NULL,
  `runs` int DEFAULT '0',
  `extras` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `wicket_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
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
) ENGINE=InnoDB AUTO_INCREMENT=724 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ball_by_ball`
--

LOCK TABLES `ball_by_ball` WRITE;
/*!40000 ALTER TABLE `ball_by_ball` DISABLE KEYS */;
INSERT INTO `ball_by_ball` VALUES (713,104,138,0,1,0,52,22,2,NULL,NULL,NULL,'2026-01-02 06:33:28'),(714,104,138,0,2,1,52,22,2,NULL,NULL,NULL,'2026-01-02 06:33:29'),(715,104,138,0,3,2,52,22,1,NULL,NULL,NULL,'2026-01-02 06:33:29'),(716,104,138,0,4,3,56,22,0,NULL,NULL,NULL,'2026-01-02 06:33:30'),(717,104,138,0,5,4,56,22,1,NULL,NULL,NULL,'2026-01-02 06:33:30'),(718,104,138,0,6,5,52,22,2,NULL,NULL,NULL,'2026-01-02 06:33:32'),(719,104,139,0,1,0,22,52,6,NULL,NULL,NULL,'2026-01-02 06:33:40'),(720,104,139,0,2,1,22,52,6,NULL,NULL,NULL,'2026-01-02 06:33:41'),(721,105,140,0,1,0,52,13,1,NULL,NULL,NULL,'2026-01-06 13:44:39'),(722,105,140,0,2,1,54,13,2,NULL,NULL,NULL,'2026-01-06 13:44:42'),(723,105,140,0,3,2,54,13,2,NULL,NULL,NULL,'2026-01-06 13:52:45');
/*!40000 ALTER TABLE `ball_by_ball` ENABLE KEYS */;
UNLOCK TABLES;

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
  `batting_team_id` int NOT NULL,
  `bowling_team_id` int NOT NULL,
  `inning_number` int NOT NULL,
  `runs` int DEFAULT '0',
  `wickets` int DEFAULT '0',
  `overs` int DEFAULT '0',
  `overs_decimal` decimal(4,1) DEFAULT '0.0',
  `legal_balls` int DEFAULT '0',
  `status` enum('in_progress','completed') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'in_progress',
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
) ENGINE=InnoDB AUTO_INCREMENT=142 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `match_innings`
--

LOCK TABLES `match_innings` WRITE;
/*!40000 ALTER TABLE `match_innings` DISABLE KEYS */;
INSERT INTO `match_innings` VALUES (138,104,50,50,2,1,8,0,1,1.0,6,'completed','2026-01-02 06:33:22','2026-01-02 06:33:32',56,52,22),(139,104,2,2,50,2,12,0,0,0.2,2,'completed','2026-01-02 06:33:35','2026-01-02 06:33:41',22,14,52),(140,105,50,50,2,1,5,0,0,0.3,3,'completed','2026-01-06 13:44:33','2026-01-06 13:54:26',54,52,13),(141,105,2,2,50,2,0,0,0,0.0,0,'completed','2026-01-06 13:54:27','2026-01-06 13:54:31',NULL,NULL,NULL);
/*!40000 ALTER TABLE `match_innings` ENABLE KEYS */;
UNLOCK TABLES;

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
  `venue` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('not_started','live','completed','abandoned','scheduled') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'not_started',
  `overs` int DEFAULT '20',
  `winner_team_id` int DEFAULT NULL,
  `creator_id` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `target_score` int DEFAULT NULL,
  `team1_lineup` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `team2_lineup` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
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
) ENGINE=InnoDB AUTO_INCREMENT=107 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matches`
--

LOCK TABLES `matches` WRITE;
/*!40000 ALTER TABLE `matches` DISABLE KEYS */;
INSERT INTO `matches` VALUES (104,NULL,50,2,'2026-01-02 11:33:20','Unknown','completed',1,2,14,'2026-01-02 06:33:20','2026-01-02 06:33:41',9,NULL,NULL),(105,NULL,50,2,'2026-01-06 18:44:32','gh','live',2,NULL,14,'2026-01-06 13:44:30','2026-01-06 13:54:26',6,NULL,NULL);
/*!40000 ALTER TABLE `matches` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `password_resets`
--

DROP TABLE IF EXISTS `password_resets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `password_resets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `token_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `password_resets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `password_resets`
--

LOCK TABLES `password_resets` WRITE;
/*!40000 ALTER TABLE `password_resets` DISABLE KEYS */;
/*!40000 ALTER TABLE `password_resets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `player_match_stats`
--

DROP TABLE IF EXISTS `player_match_stats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
) ENGINE=InnoDB AUTO_INCREMENT=1351 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_match_stats`
--

LOCK TABLES `player_match_stats` WRITE;
/*!40000 ALTER TABLE `player_match_stats` DISABLE KEYS */;
INSERT INTO `player_match_stats` VALUES (1329,104,52,7,4,0,0,0,2,12,0,0,'2026-01-02 06:33:28','2026-01-02 06:33:41'),(1330,104,22,12,2,0,2,0,6,8,0,0,'2026-01-02 06:33:28','2026-01-02 06:33:41'),(1335,104,56,1,2,0,0,0,0,0,0,0,'2026-01-02 06:33:30','2026-01-02 06:33:30'),(1345,105,52,1,1,0,0,0,0,0,0,0,'2026-01-06 13:44:39','2026-01-06 13:44:39'),(1346,105,13,0,0,0,0,0,3,5,0,0,'2026-01-06 13:44:39','2026-01-06 13:52:45'),(1347,105,54,4,2,0,0,0,0,0,0,0,'2026-01-06 13:44:42','2026-01-06 13:52:45');
/*!40000 ALTER TABLE `player_match_stats` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `players`
--

DROP TABLE IF EXISTS `players`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `players` (
  `id` int NOT NULL AUTO_INCREMENT,
  `player_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `player_role` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `player_image_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `players`
--

LOCK TABLES `players` WRITE;
/*!40000 ALTER TABLE `players` DISABLE KEYS */;
INSERT INTO `players` VALUES (13,'1','Batsman',NULL,2,0,0,12,1,0,0,12.00,0.00,0,'2025-12-17 13:42:23','2026-01-02 05:46:58'),(14,'2','Batsman',NULL,2,0,0,0,0,0,0,0.00,0.00,0,'2025-12-17 13:42:27','2025-12-17 13:42:27'),(15,'3','Batsman',NULL,2,0,0,0,0,0,0,0.00,0.00,0,'2025-12-17 13:42:30','2025-12-17 13:42:30'),(16,'4','Batsman',NULL,2,0,0,0,0,0,0,0.00,0.00,0,'2025-12-17 13:42:33','2025-12-17 13:42:33'),(17,'5','Batsman',NULL,2,0,0,0,0,0,0,0.00,0.00,0,'2025-12-17 13:42:36','2025-12-17 13:42:36'),(18,'6','Batsman',NULL,2,0,0,0,0,0,0,0.00,0.00,0,'2025-12-17 13:42:40','2025-12-17 13:42:40'),(19,'7','Batsman',NULL,2,0,0,0,0,0,0,0.00,0.00,0,'2025-12-17 13:42:44','2025-12-17 13:42:44'),(20,'8','Batsman',NULL,2,0,0,0,0,0,0,0.00,0.00,0,'2025-12-17 13:42:48','2025-12-17 13:42:48'),(21,'9','Batsman',NULL,2,0,0,0,0,0,0,0.00,0.00,0,'2025-12-17 13:42:52','2025-12-17 13:42:52'),(22,'0','Batsman',NULL,2,0,0,12,1,0,0,12.00,0.00,0,'2025-12-17 13:42:55','2026-01-02 06:33:41'),(23,'10','Batsman',NULL,2,0,0,12,1,0,0,12.00,0.00,0,'2025-12-17 13:43:02','2026-01-02 05:05:48'),(24,'11','Batsman',NULL,2,0,0,0,2,0,0,0.00,0.00,0,'2025-12-17 13:43:07','2026-01-02 05:46:58'),(25,'13','Batsman',NULL,2,0,0,0,0,0,0,0.00,0.00,0,'2025-12-17 13:43:12','2025-12-17 13:43:12'),(51,'A','Batsman',NULL,50,0,0,7,2,0,0,2.33,0.00,0,'2025-12-30 09:49:16','2026-01-02 05:46:58'),(52,'B','Batsman',NULL,50,0,0,9,2,0,0,5.33,0.00,0,'2025-12-30 09:49:19','2026-01-02 06:33:41'),(53,'C','Batsman',NULL,50,0,0,4,1,0,0,4.00,0.00,0,'2025-12-30 09:49:21','2026-01-02 05:46:58'),(54,'F','Batsman',NULL,50,0,0,0,0,0,0,0.00,0.00,0,'2025-12-30 09:49:26','2025-12-30 09:49:26'),(55,'K','Batsman',NULL,50,0,0,0,0,0,0,0.00,0.00,0,'2025-12-30 09:49:28','2025-12-30 09:49:28'),(56,'I','Batsman',NULL,50,0,0,1,1,0,0,1.00,0.00,0,'2025-12-30 09:49:33','2026-01-02 06:33:41'),(57,'W','Batsman',NULL,50,0,0,0,0,0,0,0.00,0.00,0,'2025-12-30 09:49:44','2025-12-30 09:49:44'),(58,'R','Batsman',NULL,50,0,0,0,0,0,0,0.00,0.00,0,'2025-12-30 09:49:58','2025-12-30 09:49:58'),(59,'Y','Batsman',NULL,50,0,0,0,0,0,0,0.00,0.00,0,'2025-12-30 09:50:02','2025-12-30 09:50:02'),(60,'Z','Batsman',NULL,50,0,0,0,0,0,0,0.00,0.00,0,'2025-12-30 09:50:15','2025-12-30 09:50:15'),(61,'B','Batsman',NULL,50,0,0,4,1,0,0,4.00,0.00,0,'2025-12-30 09:50:20','2026-01-02 05:05:48'),(62,'M','Batsman',NULL,50,0,0,0,0,0,0,0.00,0.00,0,'2025-12-30 09:50:23','2025-12-30 09:50:23'),(63,'P','Batsman',NULL,50,0,0,0,0,0,0,0.00,0.00,0,'2025-12-30 09:50:27','2025-12-30 09:50:27');
/*!40000 ALTER TABLE `players` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `refresh_tokens`
--

DROP TABLE IF EXISTS `refresh_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `refresh_tokens` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `token` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_revoked` tinyint(1) DEFAULT '0',
  `revoked_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `refresh_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `refresh_tokens`
--

LOCK TABLES `refresh_tokens` WRITE;
/*!40000 ALTER TABLE `refresh_tokens` DISABLE KEYS */;
INSERT INTO `refresh_tokens` VALUES (3,2,'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjIsInR5cCI6InJlZnJlc2giLCJpc3MiOiJjcmljLWxlYWd1ZS1hdXRoIiwiYXVkIjoiY3JpYy1sZWFndWUtYXBwIiwiaWF0IjoxNzY1OTc4ODkwLCJleHAiOjE4MjY0NTg4OTB9.DEerzXuixSwL2fqcJQ35WscHbAFREgjewpW7cPSwkt4',0,NULL,'2025-12-17 13:41:30'),(4,2,'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjIsInR5cCI6InJlZnJlc2giLCJpc3MiOiJjcmljLWxlYWd1ZS1hdXRoIiwiYXVkIjoiY3JpYy1sZWFndWUtYXBwIiwiaWF0IjoxNzY1OTc4OTEyLCJleHAiOjE4MjY0NTg5MTJ9.UliTwizSwo4ae8qVL6-XIH2bxQDYhQEKL2lwuhNHiJA',0,NULL,'2025-12-17 13:41:52'),(7,3,'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjMsInR5cCI6InJlZnJlc2giLCJpc3MiOiJjcmljLWxlYWd1ZS1hdXRoIiwiYXVkIjoiY3JpYy1sZWFndWUtYXBwIiwiaWF0IjoxNzY2MTU3MzI4LCJleHAiOjE4MjY2MzczMjh9.ZF5RHIfOVYV9Qf2CWOVSfwq3Ardx-DSjLC20PHLxIhQ',0,NULL,'2025-12-19 15:15:28'),(15,3,'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjMsInR5cCI6InJlZnJlc2giLCJpc3MiOiJjcmljLWxlYWd1ZS1hdXRoIiwiYXVkIjoiY3JpYy1sZWFndWUtYXBwIiwiaWF0IjoxNzY2NDE3ODgxLCJleHAiOjE4MjY4OTc4ODF9.1zRF0MmE5vreBdutBhZpP1ggH7LskdsI2jLmL0Sc3BE',0,NULL,'2025-12-22 15:38:01'),(23,3,'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjMsInR5cCI6InJlZnJlc2giLCJpc3MiOiJjcmljLWxlYWd1ZS1hdXRoIiwiYXVkIjoiY3JpYy1sZWFndWUtYXBwIiwiaWF0IjoxNzY2NTA4NTc0LCJleHAiOjE4MjY5ODg1NzR9.KOUiJWpzXBxv98cjwBa560sQVVz2LXip5yNj3pv-pJI',0,NULL,'2025-12-23 16:49:34'),(35,3,'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjMsInR5cCI6InJlZnJlc2giLCJpc3MiOiJjcmljLWxlYWd1ZS1hdXRoIiwiYXVkIjoiY3JpYy1sZWFndWUtYXBwIiwiaWF0IjoxNzY3MDc3MjUyLCJleHAiOjE4Mjc1NTcyNTJ9.2LLkrtmCW1kKjDtCJ8jXIF2kGy5fEpAjUHH5TX74aTM',0,NULL,'2025-12-30 06:47:32'),(36,14,'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjE0LCJ0eXAiOiJyZWZyZXNoIiwiaXNzIjoiY3JpYy1sZWFndWUtYXV0aCIsImF1ZCI6ImNyaWMtbGVhZ3VlLWFwcCIsImlhdCI6MTc2NzA4ODEzNSwiZXhwIjoxODI3NTY4MTM1fQ.J2WEWXEjWZK3HExvJMDVe5NA40LMoggTxqZ-U52tshQ',0,NULL,'2025-12-30 09:48:55'),(37,14,'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjE0LCJ0eXAiOiJyZWZyZXNoIiwiaXNzIjoiY3JpYy1sZWFndWUtYXV0aCIsImF1ZCI6ImNyaWMtbGVhZ3VlLWFwcCIsImlhdCI6MTc2NzA4ODE0MSwiZXhwIjoxODI3NTY4MTQxfQ.6IgWCCf7rrUQsNCx6yKmlyqvbxgwhQegKjok6EwQtGU',0,NULL,'2025-12-30 09:49:01'),(38,14,'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjE0LCJ0eXAiOiJyZWZyZXNoIiwiaXNzIjoiY3JpYy1sZWFndWUtYXV0aCIsImF1ZCI6ImNyaWMtbGVhZ3VlLWFwcCIsImlhdCI6MTc2NzI0NjQxMSwiZXhwIjoxODI3NzI2NDExfQ.1vWaknFgRKRNAWHYDyF_fv53RD77pySxo_ITc-oox30',0,NULL,'2026-01-01 05:46:51'),(39,14,'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjE0LCJ0eXAiOiJyZWZyZXNoIiwiaXNzIjoiY3JpYy1sZWFndWUtYXV0aCIsImF1ZCI6ImNyaWMtbGVhZ3VlLWFwcCIsImlhdCI6MTc2NzMyNzk2MiwiZXhwIjoxODI3ODA3OTYyfQ.s69DXLZfnXtUvc_Nakn85RjCqZoXjkd1fZpO9qiwka0',0,NULL,'2026-01-02 04:26:02'),(40,3,'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjMsInR5cCI6InJlZnJlc2giLCJpc3MiOiJjcmljLWxlYWd1ZS1hdXRoIiwiYXVkIjoiY3JpYy1sZWFndWUtYXBwIiwiaWF0IjoxNzY3MzMyOTg0LCJleHAiOjE4Mjc4MTI5ODR9.dGxGJ1l9iJk6iusfntqNRCFdKYg4gXv5qsSMdZkv4-0',0,NULL,'2026-01-02 05:49:44'),(41,14,'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjE0LCJ0eXAiOiJyZWZyZXNoIiwiaXNzIjoiY3JpYy1sZWFndWUtYXV0aCIsImF1ZCI6ImNyaWMtbGVhZ3VlLWFwcCIsImlhdCI6MTc2NzcwNjk4NywiZXhwIjoxODI4MTg2OTg3fQ.2Uip5zoFzpyIxLwaKNTnlGLh8a5Ou8N-KBSp9lPZBmE',0,NULL,'2026-01-06 13:43:07'),(53,26,'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjI2LCJ0eXAiOiJyZWZyZXNoIiwiaXNzIjoiY3JpYy1sZWFndWUtYXV0aCIsImF1ZCI6ImNyaWMtbGVhZ3VlLWFwcCIsImlhdCI6MTc2NzcxODcyNywiZXhwIjoxODI4MTk4NzI3fQ.uvd7ibc0R4ajDyXv620N4WORqjmHHVDMuV6v-CHCT6g',0,NULL,'2026-01-06 16:58:47');
/*!40000 ALTER TABLE `refresh_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `team_tournament_summary`
--

DROP TABLE IF EXISTS `team_tournament_summary`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `team_tournament_summary`
--

LOCK TABLES `team_tournament_summary` WRITE;
/*!40000 ALTER TABLE `team_tournament_summary` DISABLE KEYS */;
/*!40000 ALTER TABLE `team_tournament_summary` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teams`
--

DROP TABLE IF EXISTS `teams`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teams` (
  `id` int NOT NULL AUTO_INCREMENT,
  `team_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `team_location` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `team_logo_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
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
) ENGINE=InnoDB AUTO_INCREMENT=88 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teams`
--

LOCK TABLES `teams` WRITE;
/*!40000 ALTER TABLE `teams` DISABLE KEYS */;
INSERT INTO `teams` VALUES (2,'Kkr','Yuh',NULL,2,NULL,NULL,3,3,0,'2025-12-17 13:42:17','2026-01-02 06:33:41'),(50,'Abc','Hgh',NULL,14,NULL,NULL,3,0,0,'2025-12-30 09:49:11','2026-01-02 06:33:41'),(87,'Admin Team','HQ',NULL,26,NULL,NULL,0,0,0,'2026-01-06 16:09:03','2026-01-06 16:09:03');
/*!40000 ALTER TABLE `teams` ENABLE KEYS */;
UNLOCK TABLES;

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
  `round` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `match_date` datetime DEFAULT NULL,
  `location` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('upcoming','live','finished') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'upcoming',
  `winner_id` int DEFAULT NULL,
  `parent_match_id` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `match_id` int DEFAULT NULL,
  `team1_lineup` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `team2_lineup` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tournament_matches`
--

LOCK TABLES `tournament_matches` WRITE;
/*!40000 ALTER TABLE `tournament_matches` DISABLE KEYS */;
/*!40000 ALTER TABLE `tournament_matches` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tournament_teams`
--

DROP TABLE IF EXISTS `tournament_teams`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tournament_teams` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tournament_id` int NOT NULL,
  `team_id` int NOT NULL,
  `temp_team_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `temp_team_location` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `tournament_id` (`tournament_id`),
  KEY `team_id` (`team_id`),
  CONSTRAINT `tournament_teams_ibfk_1` FOREIGN KEY (`tournament_id`) REFERENCES `tournaments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tournament_teams_ibfk_2` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=71 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tournament_teams`
--

LOCK TABLES `tournament_teams` WRITE;
/*!40000 ALTER TABLE `tournament_teams` DISABLE KEYS */;
/*!40000 ALTER TABLE `tournament_teams` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tournaments`
--

DROP TABLE IF EXISTS `tournaments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tournaments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tournament_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `start_date` datetime NOT NULL,
  `end_date` datetime DEFAULT NULL,
  `location` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('upcoming','live','completed','abandoned') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'upcoming',
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
) ENGINE=InnoDB AUTO_INCREMENT=50 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tournaments`
--

LOCK TABLES `tournaments` WRITE;
/*!40000 ALTER TABLE `tournaments` DISABLE KEYS */;
/*!40000 ALTER TABLE `tournaments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_activity_logs`
--

DROP TABLE IF EXISTS `user_activity_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_activity_logs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `device_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `activity_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `metadata` json DEFAULT NULL,
  `ip_address` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `user_activity_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_activity_logs`
--

LOCK TABLES `user_activity_logs` WRITE;
/*!40000 ALTER TABLE `user_activity_logs` DISABLE KEYS */;
INSERT INTO `user_activity_logs` VALUES (1,NULL,'CP11.251114.006','APP_OPEN','{\"version\": \"CP11.251114.006\", \"platform\": \"android\", \"timestamp\": \"2026-01-02T11:32:30.940968\", \"device_model\": \"google Pixel 6\"}','192.168.10.20','2026-01-02 06:32:40'),(2,NULL,'CP11.251114.006','APP_OPEN','{\"version\": \"CP11.251114.006\", \"platform\": \"android\", \"timestamp\": \"2026-01-02T11:32:48.968636\", \"device_model\": \"google Pixel 6\"}','192.168.10.20','2026-01-02 06:32:47'),(3,NULL,'CP11.251114.006','APP_OPEN','{\"version\": \"CP11.251114.006\", \"platform\": \"android\", \"timestamp\": \"2026-01-06T10:51:58.530191\", \"device_model\": \"google Pixel 6\"}','192.168.10.20','2026-01-06 05:51:58'),(4,NULL,'CP11.251114.006','APP_OPEN','{\"version\": \"CP11.251114.006\", \"platform\": \"android\", \"timestamp\": \"2026-01-06T18:41:42.314125\", \"device_model\": \"google Pixel 6\"}','192.168.10.20','2026-01-06 13:41:41'),(5,NULL,'RP1A.200720.011','APP_OPEN','{\"version\": \"X6511E-H6126EFGMV-RGo-GL-240105V864\", \"platform\": \"android\", \"timestamp\": \"2026-01-06T18:52:33.430884\", \"device_model\": \"Infinix Infinix X6511E\"}','192.168.10.56','2026-01-06 13:52:36');
/*!40000 ALTER TABLE `user_activity_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_admin` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `phone_number` (`phone_number`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (2,'923123456788',NULL,'$2a$12$tONEfJciYD3pEjsQbDImJeaEsC7TLTPRftj80.1kf8VdgIoU7cuva',0,'2025-12-17 13:41:30','2025-12-17 13:41:30'),(3,'+92123456789',NULL,'$2a$10$ZrYKGsZQk71yRLpWY.9FPOtK2DdntT6dN6jPs7SsJU9/EfNkyM0XK',1,'2025-12-18 14:19:17','2025-12-18 14:19:17'),(14,'923123456789',NULL,'$2a$12$Hn.8j7NYlyb9OSPEA/yQeu/NMnKqCCP.aF4PQoZ/mC7ES5oXUnJSK',0,'2025-12-30 09:48:55','2025-12-30 09:48:55'),(26,NULL,'admin@example.com','$2a$12$C5RuQBIOgw5QBaUPGlkpiuPv/Jq9E6eep7mWl43AqaugLz5kqLI5W',1,'2026-01-06 16:04:23','2026-01-06 16:04:23');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-07 21:09:41
