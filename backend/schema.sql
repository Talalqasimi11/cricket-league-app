-- Disable foreign key checks for bulk creation
SET FOREIGN_KEY_CHECKS = 0;

-- 1. Users Table
CREATE TABLE IF NOT EXISTS `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(20) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `password_hash` varchar(255) DEFAULT NULL,
  `is_admin` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `phone_number` (`phone_number`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Auth Failures
CREATE TABLE IF NOT EXISTS `auth_failures` (
  `id` int NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(20) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `failed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `resolved_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Refresh Tokens
CREATE TABLE IF NOT EXISTS `refresh_tokens` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `token` varchar(512) NOT NULL,
  `is_revoked` tinyint(1) DEFAULT '0',
  `revoked_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `refresh_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Password Resets
CREATE TABLE IF NOT EXISTS `password_resets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `token_hash` varchar(255) NOT NULL,
  `used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `password_resets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Teams
CREATE TABLE IF NOT EXISTS `teams` (
  `id` int NOT NULL AUTO_INCREMENT,
  `team_name` varchar(100) NOT NULL,
  `team_location` varchar(100) DEFAULT NULL,
  `team_logo_url` varchar(255) DEFAULT NULL,
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
  CONSTRAINT `teams_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Players
CREATE TABLE IF NOT EXISTS `players` (
  `id` int NOT NULL AUTO_INCREMENT,
  `player_name` varchar(100) NOT NULL,
  `player_role` varchar(50) NOT NULL,
  `player_image_url` varchar(255) DEFAULT NULL,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add foreign keys for teams captain/vice-captain (after players table exists)
ALTER TABLE `teams` 
ADD CONSTRAINT `teams_captain_fk` FOREIGN KEY (`captain_player_id`) REFERENCES `players` (`id`) ON DELETE SET NULL,
ADD CONSTRAINT `teams_vice_captain_fk` FOREIGN KEY (`vice_captain_player_id`) REFERENCES `players` (`id`) ON DELETE SET NULL;

-- 7. Tournaments
CREATE TABLE IF NOT EXISTS `tournaments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tournament_name` varchar(100) NOT NULL,
  `start_date` datetime NOT NULL,
  `end_date` datetime DEFAULT NULL,
  `location` varchar(100) NOT NULL,
  `status` enum('upcoming','live','completed','abandoned') DEFAULT 'upcoming',
  `overs` int DEFAULT '20',
  `created_by` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `created_by` (`created_by`),
  CONSTRAINT `tournaments_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. Tournament Teams
CREATE TABLE IF NOT EXISTS `tournament_teams` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tournament_id` int NOT NULL,
  `team_id` int NOT NULL,
  `temp_team_name` varchar(100) DEFAULT NULL,
  `temp_team_location` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `tournament_id` (`tournament_id`),
  KEY `team_id` (`team_id`),
  CONSTRAINT `tournament_teams_ibfk_1` FOREIGN KEY (`tournament_id`) REFERENCES `tournaments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tournament_teams_ibfk_2` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. Matches (Generic matches table)
CREATE TABLE IF NOT EXISTS `matches` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tournament_id` int DEFAULT NULL,
  `team1_id` int NOT NULL,
  `team2_id` int NOT NULL,
  `match_datetime` datetime NOT NULL,
  `venue` varchar(100) NOT NULL,
  `status` enum('not_started','live','completed','abandoned','scheduled') DEFAULT 'not_started',
  `overs` int DEFAULT '20',
  `winner_team_id` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `tournament_id` (`tournament_id`),
  KEY `team1_id` (`team1_id`),
  KEY `team2_id` (`team2_id`),
  KEY `winner_team_id` (`winner_team_id`),
  CONSTRAINT `matches_ibfk_1` FOREIGN KEY (`tournament_id`) REFERENCES `tournaments` (`id`) ON DELETE SET NULL,
  CONSTRAINT `matches_ibfk_2` FOREIGN KEY (`team1_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `matches_ibfk_3` FOREIGN KEY (`team2_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `matches_ibfk_4` FOREIGN KEY (`winner_team_id`) REFERENCES `teams` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. Tournament Matches (Specific structure for tournament brackets)
CREATE TABLE IF NOT EXISTS `tournament_matches` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tournament_id` int NOT NULL,
  `team1_id` int DEFAULT NULL,
  `team2_id` int DEFAULT NULL,
  `team1_tt_id` int DEFAULT NULL,
  `team2_tt_id` int DEFAULT NULL,
  `round` varchar(50) NOT NULL,
  `match_date` datetime DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `status` enum('upcoming','live','finished') DEFAULT 'upcoming',
  `winner_id` int DEFAULT NULL,
  `parent_match_id` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `tournament_id` (`tournament_id`),
  KEY `team1_id` (`team1_id`),
  KEY `team2_id` (`team2_id`),
  KEY `winner_id` (`winner_id`),
  CONSTRAINT `tournament_matches_ibfk_1` FOREIGN KEY (`tournament_id`) REFERENCES `tournaments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tournament_matches_ibfk_2` FOREIGN KEY (`team1_id`) REFERENCES `teams` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tournament_matches_ibfk_3` FOREIGN KEY (`team2_id`) REFERENCES `teams` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tournament_matches_ibfk_4` FOREIGN KEY (`winner_id`) REFERENCES `teams` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- 11. Match Innings
CREATE TABLE IF NOT EXISTS `match_innings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `match_id` int NOT NULL,
  `team_id` int NOT NULL, -- "Team currently batting" redundancy or legacy
  `batting_team_id` int NOT NULL,
  `bowling_team_id` int NOT NULL,
  `inning_number` int NOT NULL,
  `runs` int DEFAULT '0',
  `wickets` int DEFAULT '0',
  `overs` int DEFAULT '0',
  `overs_decimal` decimal(4,1) DEFAULT '0.0',
  `legal_balls` int DEFAULT '0',
  `status` enum('in_progress','completed') DEFAULT 'in_progress',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `match_id` (`match_id`),
  KEY `batting_team_id` (`batting_team_id`),
  KEY `bowling_team_id` (`bowling_team_id`),
  CONSTRAINT `match_innings_ibfk_1` FOREIGN KEY (`match_id`) REFERENCES `matches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `match_innings_ibfk_2` FOREIGN KEY (`batting_team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `match_innings_ibfk_3` FOREIGN KEY (`bowling_team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. Ball By Ball
CREATE TABLE IF NOT EXISTS `ball_by_ball` (
  `id` int NOT NULL AUTO_INCREMENT,
  `match_id` int NOT NULL,
  `inning_id` int NOT NULL,
  `over_number` int NOT NULL,
  `ball_number` int NOT NULL,
  `sequence` int NOT NULL,
  `batsman_id` int NOT NULL,
  `bowler_id` int NOT NULL,
  `runs` int DEFAULT '0',
  `extras` varchar(20) DEFAULT NULL, -- wide, no-ball, bye, leg-bye
  `wicket_type` varchar(50) DEFAULT NULL,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 13. Player Match Stats
CREATE TABLE IF NOT EXISTS `player_match_stats` (
  `id` int NOT NULL AUTO_INCREMENT,
  `match_id` int NOT NULL,
  `player_id` int NOT NULL,
  `runs` int DEFAULT '0',
  `balls_faced` int DEFAULT '0',
  `fours` int DEFAULT '0',
  `sixes` int DEFAULT '0',
  `balls_bowled` int DEFAULT '0',
  `runs_conceded` int DEFAULT '0',
  `wickets` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_match_player` (`match_id`, `player_id`),
  KEY `player_id` (`player_id`),
  CONSTRAINT `player_match_stats_ibfk_1` FOREIGN KEY (`match_id`) REFERENCES `matches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `player_match_stats_ibfk_2` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;
 
 c o n s t   {   d b   }   =   r e q u i r e ( ' . / c o n f i g / d b ' ) ;  
  
 a s y n c   f u n c t i o n   c r e a t e T a b l e ( )   {  
         t r y   {  
                 c o n s o l e . l o g ( " C r e a t i n g   t e a m _ t o u r n a m e n t _ s u m m a r y   t a b l e . . . " ) ;  
                 c o n s t   s q l   =   `  
                         C R E A T E   T A B L E   I F   N O T   E X I S T S   \ ` t e a m _ t o u r n a m e n t _ s u m m a r y \ `   (  
                             \ ` i d \ `   i n t   N O T   N U L L   A U T O _ I N C R E M E N T ,  
                             \ ` t o u r n a m e n t _ i d \ `   i n t   N O T   N U L L ,  
                             \ ` t e a m _ i d \ `   i n t   N O T   N U L L ,  
                             \ ` m a t c h e s _ p l a y e d \ `   i n t   D E F A U L T   ' 0 ' ,  
                             \ ` m a t c h e s _ w o n \ `   i n t   D E F A U L T   ' 0 ' ,  
                             \ ` p o i n t s \ `   i n t   D E F A U L T   ' 0 ' ,  
                             \ ` n r r \ `   d e c i m a l ( 1 0 , 3 )   D E F A U L T   ' 0 . 0 0 0 ' ,  
                             \ ` c r e a t e d _ a t \ `   t i m e s t a m p   N U L L   D E F A U L T   C U R R E N T _ T I M E S T A M P ,  
                             \ ` u p d a t e d _ a t \ `   t i m e s t a m p   N U L L   D E F A U L T   C U R R E N T _ T I M E S T A M P   O N   U P D A T E   C U R R E N T _ T I M E S T A M P ,  
                             P R I M A R Y   K E Y   ( \ ` i d \ ` ) ,  
                             U N I Q U E   K E Y   \ ` u n i q u e _ s u m m a r y \ `   ( \ ` t o u r n a m e n t _ i d \ ` ,   \ ` t e a m _ i d \ ` ) ,  
                             F O R E I G N   K E Y   ( \ ` t o u r n a m e n t _ i d \ ` )   R E F E R E N C E S   \ ` t o u r n a m e n t s \ `   ( \ ` i d \ ` )   O N   D E L E T E   C A S C A D E ,  
                             F O R E I G N   K E Y   ( \ ` t e a m _ i d \ ` )   R E F E R E N C E S   \ ` t e a m s \ `   ( \ ` i d \ ` )   O N   D E L E T E   C A S C A D E  
                         )   E N G I N E = I n n o D B   D E F A U L T   C H A R S E T = u t f 8 m b 4   C O L L A T E = u t f 8 m b 4 _ u n i c o d e _ c i ;  
                 ` ;  
  
                 a w a i t   d b . q u e r y ( s q l ) ;  
                 c o n s o l e . l o g ( " ‚ S&   T a b l e   c r e a t e d   s u c c e s s f u l l y . " ) ;  
  
         }   c a t c h   ( e )   {  
                 c o n s o l e . e r r o r ( " ‚ ù R  E r r o r   c r e a t i n g   t a b l e : " ,   e . m e s s a g e ) ;  
         }   f i n a l l y   {  
                 p r o c e s s . e x i t ( ) ;  
         }  
 }  
  
 c r e a t e T a b l e ( ) ;  
 