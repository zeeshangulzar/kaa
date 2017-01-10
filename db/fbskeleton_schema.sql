-- MySQL dump 10.13  Distrib 5.6.19, for osx10.9 (x86_64)
--
-- Host: mysql.hesonline.net    Database: fbskeleton
-- ------------------------------------------------------
-- Server version	5.5.5-10.0.17-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `apps`
--

DROP TABLE IF EXISTS `apps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `apps` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL,
  `database_user_name` varchar(50) DEFAULT NULL,
  `fitbit_consumer_key` varchar(32) DEFAULT NULL,
  `fitbit_consumer_secret` varchar(32) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `garmin_key` varchar(255) DEFAULT NULL,
  `garmin_secret` varchar(255) DEFAULT NULL,
  `jawbone_key` varchar(255) DEFAULT NULL,
  `jawbone_secret` varchar(255) DEFAULT NULL,
  `fitbit_client_id` varchar(32) DEFAULT NULL,
  `fitbit_client_secret` varchar(32) DEFAULT NULL,
  `fitbit_scope` varchar(255) DEFAULT NULL,
  `fitbit_callback_url` varchar(255) DEFAULT NULL,
  `redis_namespace` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `contacts`
--

DROP TABLE IF EXISTS `contacts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `contactable_id` int(11) DEFAULT NULL,
  `contactable_type` varchar(50) DEFAULT NULL,
  `first_name` varchar(100) DEFAULT NULL,
  `last_name` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fitbit_notification_batches`
--

DROP TABLE IF EXISTS `fitbit_notification_batches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fitbit_notification_batches` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `contents` text,
  `status` varchar(1) DEFAULT 'N',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `app_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `by_status` (`status`)
) ENGINE=InnoDB AUTO_INCREMENT=2915 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `fitbit_notification_batches_view`
--

DROP TABLE IF EXISTS `fitbit_notification_batches_view`;
/*!50001 DROP VIEW IF EXISTS `fitbit_notification_batches_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `fitbit_notification_batches_view` AS SELECT 
 1 AS `id`,
 1 AS `contents`,
 1 AS `status`,
 1 AS `created_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `fitbit_notifications`
--

DROP TABLE IF EXISTS `fitbit_notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fitbit_notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fitbit_user_id` int(11) DEFAULT NULL,
  `collection_type` varchar(10) DEFAULT NULL,
  `date` date DEFAULT NULL,
  `owner_id` varchar(10) DEFAULT NULL,
  `owner_type` varchar(10) DEFAULT NULL,
  `status` varchar(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `by_status_and_collection_type` (`status`,`collection_type`),
  KEY `by_owner_id` (`owner_id`),
  KEY `by_fitbit_user_id` (`fitbit_user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=11416 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `fitbit_notifications_view`
--

DROP TABLE IF EXISTS `fitbit_notifications_view`;
/*!50001 DROP VIEW IF EXISTS `fitbit_notifications_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `fitbit_notifications_view` AS SELECT 
 1 AS `id`,
 1 AS `fitbit_user_id`,
 1 AS `collection_type`,
 1 AS `date`,
 1 AS `owner_id`,
 1 AS `owner_type`,
 1 AS `status`,
 1 AS `created_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `fitbit_oauth_tokens`
--

DROP TABLE IF EXISTS `fitbit_oauth_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fitbit_oauth_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `token` varchar(64) DEFAULT NULL,
  `secret` varchar(64) DEFAULT NULL,
  `extra_data` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `scope` varchar(255) DEFAULT NULL,
  `oauth_version` int(11) DEFAULT '1',
  `temp_secret` varchar(255) DEFAULT NULL,
  `access_token` varchar(1000) DEFAULT NULL,
  `expires_in` int(11) DEFAULT NULL,
  `access_token_fetched_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `by_app_id_and_user_id` (`app_id`,`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=194 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `fitbit_oauth_tokens_view`
--

DROP TABLE IF EXISTS `fitbit_oauth_tokens_view`;
/*!50001 DROP VIEW IF EXISTS `fitbit_oauth_tokens_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `fitbit_oauth_tokens_view` AS SELECT 
 1 AS `id`,
 1 AS `app_id`,
 1 AS `user_id`,
 1 AS `token`,
 1 AS `secret`,
 1 AS `extra_data`,
 1 AS `created_at`,
 1 AS `updated_at`,
 1 AS `scope`,
 1 AS `oauth_version`,
 1 AS `temp_secret`,
 1 AS `access_token`,
 1 AS `expires_in`,
 1 AS `access_token_fetched_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `fitbit_subscriptions`
--

DROP TABLE IF EXISTS `fitbit_subscriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fitbit_subscriptions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app_id` int(11) DEFAULT NULL,
  `collection_type` varchar(10) DEFAULT NULL,
  `owner_type` varchar(10) DEFAULT NULL,
  `owner_id` int(11) DEFAULT NULL,
  `subscriber_id` varchar(50) DEFAULT NULL,
  `subscription_id` varchar(50) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `by_owner_type_and_owner_id` (`owner_type`,`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fitbit_user_daily_activities`
--

DROP TABLE IF EXISTS `fitbit_user_daily_activities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fitbit_user_daily_activities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fitbit_user_id` int(11) DEFAULT NULL,
  `reported_on` date DEFAULT NULL,
  `log_id` int(11) DEFAULT NULL,
  `activity_parent_id` int(11) DEFAULT NULL,
  `activity_id` int(11) DEFAULT NULL,
  `duration` int(11) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `activity_parent_name` varchar(50) DEFAULT NULL,
  `has_start_time` varchar(50) DEFAULT NULL,
  `start_time` varchar(50) DEFAULT NULL,
  `is_favorite` tinyint(1) DEFAULT NULL,
  `description` varchar(50) DEFAULT NULL,
  `calories` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `by_fitbit_user_id_and_reported_on` (`fitbit_user_id`,`reported_on`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `fitbit_user_daily_activities_view`
--

DROP TABLE IF EXISTS `fitbit_user_daily_activities_view`;
/*!50001 DROP VIEW IF EXISTS `fitbit_user_daily_activities_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `fitbit_user_daily_activities_view` AS SELECT 
 1 AS `id`,
 1 AS `fitbit_user_id`,
 1 AS `reported_on`,
 1 AS `log_id`,
 1 AS `activity_parent_id`,
 1 AS `activity_id`,
 1 AS `duration`,
 1 AS `name`,
 1 AS `activity_parent_name`,
 1 AS `has_start_time`,
 1 AS `start_time`,
 1 AS `is_favorite`,
 1 AS `description`,
 1 AS `calories`,
 1 AS `created_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `fitbit_user_daily_goals`
--

DROP TABLE IF EXISTS `fitbit_user_daily_goals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fitbit_user_daily_goals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fitbit_user_id` int(11) DEFAULT NULL,
  `reported_on` date DEFAULT NULL,
  `distance` int(11) DEFAULT NULL,
  `calories_out` int(11) DEFAULT NULL,
  `floors` int(11) DEFAULT NULL,
  `active_score` int(11) DEFAULT NULL,
  `steps` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `by_fitbit_user_id_and_reported_on` (`fitbit_user_id`,`reported_on`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `fitbit_user_daily_goals_view`
--

DROP TABLE IF EXISTS `fitbit_user_daily_goals_view`;
/*!50001 DROP VIEW IF EXISTS `fitbit_user_daily_goals_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `fitbit_user_daily_goals_view` AS SELECT 
 1 AS `id`,
 1 AS `fitbit_user_id`,
 1 AS `reported_on`,
 1 AS `distance`,
 1 AS `calories_out`,
 1 AS `floors`,
 1 AS `active_score`,
 1 AS `steps`,
 1 AS `created_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `fitbit_user_daily_summaries`
--

DROP TABLE IF EXISTS `fitbit_user_daily_summaries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fitbit_user_daily_summaries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fitbit_user_id` int(11) DEFAULT NULL,
  `reported_on` date DEFAULT NULL,
  `steps` int(11) DEFAULT NULL,
  `elevation` int(11) DEFAULT NULL,
  `floors` int(11) DEFAULT NULL,
  `active_score` int(11) DEFAULT NULL,
  `activity_calories` int(11) DEFAULT NULL,
  `marginal_calories` int(11) DEFAULT NULL,
  `calories_out` int(11) DEFAULT NULL,
  `very_active_minutes` int(11) DEFAULT NULL,
  `fairly_active_minutes` int(11) DEFAULT NULL,
  `lightly_active_minutes` int(11) DEFAULT NULL,
  `sedentary_minutes` int(11) DEFAULT NULL,
  `distance` decimal(8,2) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `tracker_steps` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `by_fitbit_user_id_and_reported_on_unique` (`fitbit_user_id`,`reported_on`),
  KEY `by_fitbit_user_id_and_reported_on` (`fitbit_user_id`,`reported_on`)
) ENGINE=InnoDB AUTO_INCREMENT=236613 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `fitbit_user_daily_summaries_view`
--

DROP TABLE IF EXISTS `fitbit_user_daily_summaries_view`;
/*!50001 DROP VIEW IF EXISTS `fitbit_user_daily_summaries_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `fitbit_user_daily_summaries_view` AS SELECT 
 1 AS `id`,
 1 AS `fitbit_user_id`,
 1 AS `reported_on`,
 1 AS `steps`,
 1 AS `elevation`,
 1 AS `floors`,
 1 AS `active_score`,
 1 AS `activity_calories`,
 1 AS `marginal_calories`,
 1 AS `calories_out`,
 1 AS `very_active_minutes`,
 1 AS `fairly_active_minutes`,
 1 AS `lightly_active_minutes`,
 1 AS `sedentary_minutes`,
 1 AS `distance`,
 1 AS `created_at`,
 1 AS `updated_at`,
 1 AS `tracker_steps`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `fitbit_user_daily_summary_distances`
--

DROP TABLE IF EXISTS `fitbit_user_daily_summary_distances`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fitbit_user_daily_summary_distances` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fitbit_user_daily_summary_id` int(11) DEFAULT NULL,
  `fitbit_user_id` int(11) DEFAULT NULL,
  `reported_on` date DEFAULT NULL,
  `activity` varchar(50) DEFAULT NULL,
  `distance` decimal(8,2) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `by_fitbit_user_daily_summary_id` (`fitbit_user_daily_summary_id`),
  KEY `by_fitbit_user_id_and_reported_on` (`fitbit_user_id`,`reported_on`)
) ENGINE=InnoDB AUTO_INCREMENT=16682 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `fitbit_user_daily_summary_distances_view`
--

DROP TABLE IF EXISTS `fitbit_user_daily_summary_distances_view`;
/*!50001 DROP VIEW IF EXISTS `fitbit_user_daily_summary_distances_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `fitbit_user_daily_summary_distances_view` AS SELECT 
 1 AS `id`,
 1 AS `fitbit_user_daily_summary_id`,
 1 AS `fitbit_user_id`,
 1 AS `reported_on`,
 1 AS `activity`,
 1 AS `distance`,
 1 AS `created_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `fitbit_user_devices`
--

DROP TABLE IF EXISTS `fitbit_user_devices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fitbit_user_devices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fitbit_user_id` int(11) DEFAULT NULL,
  `remote_id` int(11) DEFAULT NULL,
  `last_sync_time` datetime DEFAULT NULL,
  `type_of_device` varchar(255) DEFAULT NULL,
  `device_version` varchar(255) DEFAULT NULL,
  `battery` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `by_fitbit_user_id` (`fitbit_user_id`),
  KEY `by_remote_id` (`remote_id`)
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `fitbit_user_devices_view`
--

DROP TABLE IF EXISTS `fitbit_user_devices_view`;
/*!50001 DROP VIEW IF EXISTS `fitbit_user_devices_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `fitbit_user_devices_view` AS SELECT 
 1 AS `id`,
 1 AS `fitbit_user_id`,
 1 AS `remote_id`,
 1 AS `last_sync_time`,
 1 AS `type_of_device`,
 1 AS `device_version`,
 1 AS `battery`,
 1 AS `created_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `fitbit_users`
--

DROP TABLE IF EXISTS `fitbit_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fitbit_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `app_id` int(11) DEFAULT NULL,
  `height_unit` varchar(10) DEFAULT NULL,
  `encoded_id` varchar(10) DEFAULT NULL,
  `date_of_birth` varchar(10) DEFAULT NULL,
  `avatar` varchar(255) DEFAULT NULL,
  `glucose_unit` varchar(10) DEFAULT NULL,
  `gender` varchar(10) DEFAULT NULL,
  `stride_length_running` int(11) DEFAULT NULL,
  `distance_unit` varchar(10) DEFAULT NULL,
  `member_since` varchar(10) DEFAULT NULL,
  `foods_locale` varchar(10) DEFAULT NULL,
  `timezone` varchar(50) DEFAULT NULL,
  `water_unit` varchar(10) DEFAULT NULL,
  `stride_length_walking` int(11) DEFAULT NULL,
  `locale` varchar(10) DEFAULT NULL,
  `height` decimal(11,3) DEFAULT NULL,
  `country` varchar(10) DEFAULT NULL,
  `weight_unit` varchar(10) DEFAULT NULL,
  `weight` int(11) DEFAULT NULL,
  `offset_from_utc_millis` int(11) DEFAULT NULL,
  `display_name` varchar(50) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `by_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4636 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `fitbit_users_view`
--

DROP TABLE IF EXISTS `fitbit_users_view`;
/*!50001 DROP VIEW IF EXISTS `fitbit_users_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `fitbit_users_view` AS SELECT 
 1 AS `id`,
 1 AS `user_id`,
 1 AS `app_id`,
 1 AS `height_unit`,
 1 AS `encoded_id`,
 1 AS `date_of_birth`,
 1 AS `avatar`,
 1 AS `glucose_unit`,
 1 AS `gender`,
 1 AS `stride_length_running`,
 1 AS `distance_unit`,
 1 AS `member_since`,
 1 AS `foods_locale`,
 1 AS `timezone`,
 1 AS `water_unit`,
 1 AS `stride_length_walking`,
 1 AS `locale`,
 1 AS `height`,
 1 AS `country`,
 1 AS `weight_unit`,
 1 AS `weight`,
 1 AS `offset_from_utc_millis`,
 1 AS `display_name`,
 1 AS `created_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `garmin_data`
--

DROP TABLE IF EXISTS `garmin_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `garmin_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `garmin_device_id` int(11) DEFAULT NULL,
  `remote_id` varchar(255) DEFAULT NULL,
  `time_start` bigint(20) DEFAULT NULL,
  `duration` int(11) DEFAULT NULL,
  `steps` int(11) DEFAULT NULL,
  `is_acknowledged` tinyint(1) DEFAULT '0',
  `start_time_offset` int(11) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `by_remote_id` (`remote_id`),
  KEY `by_garmin_device_id_and_time_start` (`garmin_device_id`,`time_start`)
) ENGINE=InnoDB AUTO_INCREMENT=2302 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `garmin_devices`
--

DROP TABLE IF EXISTS `garmin_devices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `garmin_devices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `device_id` varchar(255) DEFAULT NULL,
  `device_type` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `by_device_id` (`device_id`),
  KEY `by_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `garmin_oauth_tokens`
--

DROP TABLE IF EXISTS `garmin_oauth_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `garmin_oauth_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `token` varchar(50) DEFAULT NULL,
  `secret` varchar(50) DEFAULT NULL,
  `extra_data` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `by_app_id_and_user_id` (`app_id`,`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `garmin_oauth_tokens_from_2014`
--

DROP TABLE IF EXISTS `garmin_oauth_tokens_from_2014`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `garmin_oauth_tokens_from_2014` (
  `id` int(11) NOT NULL DEFAULT '0',
  `app_id` int(11) DEFAULT NULL,
  `token` varchar(255) DEFAULT NULL,
  `secret` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `garmin_oauth_tokens_view`
--

DROP TABLE IF EXISTS `garmin_oauth_tokens_view`;
/*!50001 DROP VIEW IF EXISTS `garmin_oauth_tokens_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `garmin_oauth_tokens_view` AS SELECT 
 1 AS `id`,
 1 AS `app_id`,
 1 AS `user_id`,
 1 AS `token`,
 1 AS `secret`,
 1 AS `extra_data`,
 1 AS `created_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `garmin_wellness_summaries`
--

DROP TABLE IF EXISTS `garmin_wellness_summaries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `garmin_wellness_summaries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `reported_on` date DEFAULT NULL,
  `steps` bigint(20) DEFAULT NULL,
  `start_time` bigint(20) DEFAULT NULL,
  `duration_secs` bigint(20) DEFAULT NULL,
  `start_time_offset` bigint(20) DEFAULT NULL,
  `active_secs` bigint(20) DEFAULT NULL,
  `distance` float DEFAULT NULL,
  `activity_type` varchar(20) DEFAULT NULL,
  `kcal` float DEFAULT NULL,
  `voltage` float DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `by_app_id_user_id_and_reported_on` (`app_id`,`user_id`,`reported_on`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `garmin_wellness_summaries_view`
--

DROP TABLE IF EXISTS `garmin_wellness_summaries_view`;
/*!50001 DROP VIEW IF EXISTS `garmin_wellness_summaries_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `garmin_wellness_summaries_view` AS SELECT 
 1 AS `id`,
 1 AS `app_id`,
 1 AS `user_id`,
 1 AS `reported_on`,
 1 AS `steps`,
 1 AS `start_time`,
 1 AS `duration_secs`,
 1 AS `start_time_offset`,
 1 AS `active_secs`,
 1 AS `distance`,
 1 AS `activity_type`,
 1 AS `kcal`,
 1 AS `voltage`,
 1 AS `created_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `jawbone_move_data`
--

DROP TABLE IF EXISTS `jawbone_move_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `jawbone_move_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `jawbone_user_id` int(11) DEFAULT NULL,
  `xid` varchar(50) DEFAULT NULL,
  `title` varchar(40) DEFAULT NULL,
  `on_date` date DEFAULT NULL,
  `time_created` int(11) DEFAULT NULL,
  `time_updated` int(11) DEFAULT NULL,
  `time_completed` int(11) DEFAULT NULL,
  `snapshot_image` varchar(255) DEFAULT NULL,
  `distance` float DEFAULT NULL,
  `km` float DEFAULT NULL,
  `steps` int(11) DEFAULT NULL,
  `active_time` int(11) DEFAULT NULL,
  `longest_active` int(11) DEFAULT NULL,
  `inactive_time` int(11) DEFAULT NULL,
  `longest_idle` int(11) DEFAULT NULL,
  `calories` float DEFAULT NULL,
  `bmr_day` float DEFAULT NULL,
  `bmr` float DEFAULT NULL,
  `bg_calories` float DEFAULT NULL,
  `wo_calories` float DEFAULT NULL,
  `wo_time` int(11) DEFAULT NULL,
  `wo_active_time` int(11) DEFAULT NULL,
  `wo_count` int(11) DEFAULT NULL,
  `wo_longest` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `by_jawbone_user_id_and_on_date` (`jawbone_user_id`,`on_date`)
) ENGINE=InnoDB AUTO_INCREMENT=995 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `jawbone_move_data_old`
--

DROP TABLE IF EXISTS `jawbone_move_data_old`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `jawbone_move_data_old` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `jawbone_user_id` int(11) DEFAULT NULL,
  `xid` varchar(50) DEFAULT NULL,
  `title` varchar(40) DEFAULT NULL,
  `on_date` date DEFAULT NULL,
  `time_created` int(11) DEFAULT NULL,
  `time_updated` int(11) DEFAULT NULL,
  `time_completed` int(11) DEFAULT NULL,
  `snapshot_image` varchar(255) DEFAULT NULL,
  `distance` int(11) DEFAULT NULL,
  `km` int(11) DEFAULT NULL,
  `steps` int(11) DEFAULT NULL,
  `active_time` int(11) DEFAULT NULL,
  `longest_active` int(11) DEFAULT NULL,
  `inactive_time` int(11) DEFAULT NULL,
  `longest_idle` int(11) DEFAULT NULL,
  `calories` int(11) DEFAULT NULL,
  `bmr_day` int(11) DEFAULT NULL,
  `bmr` int(11) DEFAULT NULL,
  `bg_calories` int(11) DEFAULT NULL,
  `wo_calories` int(11) DEFAULT NULL,
  `wo_time` int(11) DEFAULT NULL,
  `wo_active_time` int(11) DEFAULT NULL,
  `wo_count` int(11) DEFAULT NULL,
  `wo_longest` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `by_jawbone_user_id_and_on_date` (`jawbone_user_id`,`on_date`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `jawbone_move_data_view`
--

DROP TABLE IF EXISTS `jawbone_move_data_view`;
/*!50001 DROP VIEW IF EXISTS `jawbone_move_data_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `jawbone_move_data_view` AS SELECT 
 1 AS `id`,
 1 AS `jawbone_user_id`,
 1 AS `xid`,
 1 AS `title`,
 1 AS `on_date`,
 1 AS `time_created`,
 1 AS `time_updated`,
 1 AS `time_completed`,
 1 AS `snapshot_image`,
 1 AS `distance`,
 1 AS `km`,
 1 AS `steps`,
 1 AS `active_time`,
 1 AS `longest_active`,
 1 AS `inactive_time`,
 1 AS `longest_idle`,
 1 AS `calories`,
 1 AS `bmr_day`,
 1 AS `bmr`,
 1 AS `bg_calories`,
 1 AS `wo_calories`,
 1 AS `wo_time`,
 1 AS `wo_active_time`,
 1 AS `wo_count`,
 1 AS `wo_longest`,
 1 AS `created_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `jawbone_notifications`
--

DROP TABLE IF EXISTS `jawbone_notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `jawbone_notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `jawbone_user_id` int(11) DEFAULT NULL,
  `user_xid` varchar(40) DEFAULT NULL,
  `event_xid` varchar(40) DEFAULT NULL,
  `action` varchar(30) DEFAULT NULL,
  `event_type` varchar(30) DEFAULT NULL,
  `status` varchar(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `by_status_and_type` (`status`,`event_type`),
  KEY `by_user_xid` (`user_xid`),
  KEY `by_jawbone_user_id` (`jawbone_user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=318 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `jawbone_notifications_view`
--

DROP TABLE IF EXISTS `jawbone_notifications_view`;
/*!50001 DROP VIEW IF EXISTS `jawbone_notifications_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `jawbone_notifications_view` AS SELECT 
 1 AS `id`,
 1 AS `jawbone_user_id`,
 1 AS `user_xid`,
 1 AS `event_xid`,
 1 AS `action`,
 1 AS `event_type`,
 1 AS `status`,
 1 AS `created_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `jawbone_oauth_tokens`
--

DROP TABLE IF EXISTS `jawbone_oauth_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `jawbone_oauth_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `token` varchar(255) DEFAULT NULL,
  `refresh_token` varchar(255) DEFAULT NULL,
  `expiration_date` date DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `by_app_id_and_user_id` (`app_id`,`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=62 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `jawbone_oauth_tokens_view`
--

DROP TABLE IF EXISTS `jawbone_oauth_tokens_view`;
/*!50001 DROP VIEW IF EXISTS `jawbone_oauth_tokens_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `jawbone_oauth_tokens_view` AS SELECT 
 1 AS `id`,
 1 AS `app_id`,
 1 AS `user_id`,
 1 AS `token`,
 1 AS `refresh_token`,
 1 AS `expiration_date`,
 1 AS `created_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `jawbone_users`
--

DROP TABLE IF EXISTS `jawbone_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `jawbone_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `app_id` int(11) DEFAULT NULL,
  `xid` varchar(40) DEFAULT NULL,
  `first_name` varchar(40) DEFAULT NULL,
  `last_name` varchar(40) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `weight` float DEFAULT NULL,
  `height` float DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `last_sync` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `by_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=222 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `jawbone_users_view`
--

DROP TABLE IF EXISTS `jawbone_users_view`;
/*!50001 DROP VIEW IF EXISTS `jawbone_users_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `jawbone_users_view` AS SELECT 
 1 AS `id`,
 1 AS `user_id`,
 1 AS `app_id`,
 1 AS `xid`,
 1 AS `first_name`,
 1 AS `last_name`,
 1 AS `image_url`,
 1 AS `weight`,
 1 AS `height`,
 1 AS `created_at`,
 1 AS `updated_at`,
 1 AS `last_sync`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `schema_migrations`
--

DROP TABLE IF EXISTS `schema_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `password` varchar(50) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `validic_fitness_data`
--

DROP TABLE IF EXISTS `validic_fitness_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `validic_fitness_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `validic_user_id` int(11) DEFAULT NULL,
  `v_id` varchar(255) DEFAULT NULL,
  `timestamp` datetime DEFAULT NULL,
  `utc_offset` varchar(255) DEFAULT NULL,
  `fitness_type` varchar(255) DEFAULT NULL,
  `intensity` varchar(255) DEFAULT NULL,
  `start_time` datetime DEFAULT NULL,
  `distance` float DEFAULT NULL,
  `duration` float DEFAULT NULL,
  `calories` float DEFAULT NULL,
  `source` varchar(255) DEFAULT NULL,
  `source_name` varchar(255) DEFAULT NULL,
  `last_updated` datetime DEFAULT NULL,
  `validated` tinyint(1) DEFAULT NULL,
  `activity_category` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `validic_history`
--

DROP TABLE IF EXISTS `validic_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `validic_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `validic_user_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `app_id` int(11) DEFAULT NULL,
  `reported_on` date DEFAULT NULL,
  `is_processed` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=987 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `validic_history_view`
--

DROP TABLE IF EXISTS `validic_history_view`;
/*!50001 DROP VIEW IF EXISTS `validic_history_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `validic_history_view` AS SELECT 
 1 AS `id`,
 1 AS `validic_user_id`,
 1 AS `user_id`,
 1 AS `app_id`,
 1 AS `reported_on`,
 1 AS `is_processed`,
 1 AS `created_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `validic_routine_data`
--

DROP TABLE IF EXISTS `validic_routine_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `validic_routine_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `validic_user_id` int(11) DEFAULT NULL,
  `v_id` varchar(255) DEFAULT NULL,
  `steps` int(11) DEFAULT NULL,
  `timestamp` datetime DEFAULT NULL,
  `utc_offset` varchar(255) DEFAULT NULL,
  `distance` float DEFAULT NULL,
  `floors` float DEFAULT NULL,
  `elevation` float DEFAULT NULL,
  `calories_burned` float DEFAULT NULL,
  `source` varchar(255) DEFAULT NULL,
  `source_name` varchar(255) DEFAULT NULL,
  `last_updated` datetime DEFAULT NULL,
  `validated` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `reported_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1667 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `validic_users`
--

DROP TABLE IF EXISTS `validic_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `validic_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `app_id` int(11) DEFAULT NULL,
  `v_id` varchar(255) DEFAULT NULL,
  `access_token` varchar(255) DEFAULT NULL,
  `applications` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=92 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Final view structure for view `fitbit_notification_batches_view`
--

/*!50001 DROP VIEW IF EXISTS `fitbit_notification_batches_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `fitbit_notification_batches_view` AS select `fitbit_notification_batches`.`id` AS `id`,`fitbit_notification_batches`.`contents` AS `contents`,`fitbit_notification_batches`.`status` AS `status`,`fitbit_notification_batches`.`created_at` AS `created_at`,`fitbit_notification_batches`.`updated_at` AS `updated_at` from `fitbit_notification_batches` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `fitbit_notifications_view`
--

/*!50001 DROP VIEW IF EXISTS `fitbit_notifications_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `fitbit_notifications_view` AS select `fitbit_notifications`.`id` AS `id`,`fitbit_notifications`.`fitbit_user_id` AS `fitbit_user_id`,`fitbit_notifications`.`collection_type` AS `collection_type`,`fitbit_notifications`.`date` AS `date`,`fitbit_notifications`.`owner_id` AS `owner_id`,`fitbit_notifications`.`owner_type` AS `owner_type`,`fitbit_notifications`.`status` AS `status`,`fitbit_notifications`.`created_at` AS `created_at`,`fitbit_notifications`.`updated_at` AS `updated_at` from ((`fitbit_notifications` join `fitbit_users` on((`fitbit_users`.`id` = `fitbit_notifications`.`fitbit_user_id`))) join `apps` on((`apps`.`id` = `fitbit_users`.`app_id`))) where (`apps`.`database_user_name` = convert(substring_index(user(),_utf8'@',1) using latin1)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `fitbit_oauth_tokens_view`
--

/*!50001 DROP VIEW IF EXISTS `fitbit_oauth_tokens_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`hesdev`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `fitbit_oauth_tokens_view` AS select `fitbit_oauth_tokens`.`id` AS `id`,`fitbit_oauth_tokens`.`app_id` AS `app_id`,`fitbit_oauth_tokens`.`user_id` AS `user_id`,`fitbit_oauth_tokens`.`token` AS `token`,`fitbit_oauth_tokens`.`secret` AS `secret`,`fitbit_oauth_tokens`.`extra_data` AS `extra_data`,`fitbit_oauth_tokens`.`created_at` AS `created_at`,`fitbit_oauth_tokens`.`updated_at` AS `updated_at`,`fitbit_oauth_tokens`.`scope` AS `scope`,`fitbit_oauth_tokens`.`oauth_version` AS `oauth_version`,`fitbit_oauth_tokens`.`temp_secret` AS `temp_secret`,`fitbit_oauth_tokens`.`access_token` AS `access_token`,`fitbit_oauth_tokens`.`expires_in` AS `expires_in`,`fitbit_oauth_tokens`.`access_token_fetched_at` AS `access_token_fetched_at` from (`fitbit_oauth_tokens` join `apps` on((`apps`.`id` = `fitbit_oauth_tokens`.`app_id`))) where (`apps`.`database_user_name` = convert(substring_index(user(),'@',1) using latin1)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `fitbit_user_daily_activities_view`
--

/*!50001 DROP VIEW IF EXISTS `fitbit_user_daily_activities_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `fitbit_user_daily_activities_view` AS select `fitbit_user_daily_activities`.`id` AS `id`,`fitbit_user_daily_activities`.`fitbit_user_id` AS `fitbit_user_id`,`fitbit_user_daily_activities`.`reported_on` AS `reported_on`,`fitbit_user_daily_activities`.`log_id` AS `log_id`,`fitbit_user_daily_activities`.`activity_parent_id` AS `activity_parent_id`,`fitbit_user_daily_activities`.`activity_id` AS `activity_id`,`fitbit_user_daily_activities`.`duration` AS `duration`,`fitbit_user_daily_activities`.`name` AS `name`,`fitbit_user_daily_activities`.`activity_parent_name` AS `activity_parent_name`,`fitbit_user_daily_activities`.`has_start_time` AS `has_start_time`,`fitbit_user_daily_activities`.`start_time` AS `start_time`,`fitbit_user_daily_activities`.`is_favorite` AS `is_favorite`,`fitbit_user_daily_activities`.`description` AS `description`,`fitbit_user_daily_activities`.`calories` AS `calories`,`fitbit_user_daily_activities`.`created_at` AS `created_at`,`fitbit_user_daily_activities`.`updated_at` AS `updated_at` from ((`fitbit_user_daily_activities` join `fitbit_users` on((`fitbit_users`.`id` = `fitbit_user_daily_activities`.`fitbit_user_id`))) join `apps` on((`apps`.`id` = `fitbit_users`.`app_id`))) where (`apps`.`database_user_name` = convert(substring_index(user(),_utf8'@',1) using latin1)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `fitbit_user_daily_goals_view`
--

/*!50001 DROP VIEW IF EXISTS `fitbit_user_daily_goals_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `fitbit_user_daily_goals_view` AS select `fitbit_user_daily_goals`.`id` AS `id`,`fitbit_user_daily_goals`.`fitbit_user_id` AS `fitbit_user_id`,`fitbit_user_daily_goals`.`reported_on` AS `reported_on`,`fitbit_user_daily_goals`.`distance` AS `distance`,`fitbit_user_daily_goals`.`calories_out` AS `calories_out`,`fitbit_user_daily_goals`.`floors` AS `floors`,`fitbit_user_daily_goals`.`active_score` AS `active_score`,`fitbit_user_daily_goals`.`steps` AS `steps`,`fitbit_user_daily_goals`.`created_at` AS `created_at`,`fitbit_user_daily_goals`.`updated_at` AS `updated_at` from ((`fitbit_user_daily_goals` join `fitbit_users` on((`fitbit_users`.`id` = `fitbit_user_daily_goals`.`fitbit_user_id`))) join `apps` on((`apps`.`id` = `fitbit_users`.`app_id`))) where (`apps`.`database_user_name` = convert(substring_index(user(),_utf8'@',1) using latin1)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `fitbit_user_daily_summaries_view`
--

/*!50001 DROP VIEW IF EXISTS `fitbit_user_daily_summaries_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`hesdev`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `fitbit_user_daily_summaries_view` AS select `fitbit_user_daily_summaries`.`id` AS `id`,`fitbit_user_daily_summaries`.`fitbit_user_id` AS `fitbit_user_id`,`fitbit_user_daily_summaries`.`reported_on` AS `reported_on`,`fitbit_user_daily_summaries`.`steps` AS `steps`,`fitbit_user_daily_summaries`.`elevation` AS `elevation`,`fitbit_user_daily_summaries`.`floors` AS `floors`,`fitbit_user_daily_summaries`.`active_score` AS `active_score`,`fitbit_user_daily_summaries`.`activity_calories` AS `activity_calories`,`fitbit_user_daily_summaries`.`marginal_calories` AS `marginal_calories`,`fitbit_user_daily_summaries`.`calories_out` AS `calories_out`,`fitbit_user_daily_summaries`.`very_active_minutes` AS `very_active_minutes`,`fitbit_user_daily_summaries`.`fairly_active_minutes` AS `fairly_active_minutes`,`fitbit_user_daily_summaries`.`lightly_active_minutes` AS `lightly_active_minutes`,`fitbit_user_daily_summaries`.`sedentary_minutes` AS `sedentary_minutes`,`fitbit_user_daily_summaries`.`distance` AS `distance`,`fitbit_user_daily_summaries`.`created_at` AS `created_at`,`fitbit_user_daily_summaries`.`updated_at` AS `updated_at`,`fitbit_user_daily_summaries`.`tracker_steps` AS `tracker_steps` from ((`fitbit_user_daily_summaries` join `fitbit_users` on((`fitbit_users`.`id` = `fitbit_user_daily_summaries`.`fitbit_user_id`))) join `apps` on((`apps`.`id` = `fitbit_users`.`app_id`))) where (`apps`.`database_user_name` = convert(substring_index(user(),'@',1) using latin1)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `fitbit_user_daily_summary_distances_view`
--

/*!50001 DROP VIEW IF EXISTS `fitbit_user_daily_summary_distances_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `fitbit_user_daily_summary_distances_view` AS select `fitbit_user_daily_summary_distances`.`id` AS `id`,`fitbit_user_daily_summary_distances`.`fitbit_user_daily_summary_id` AS `fitbit_user_daily_summary_id`,`fitbit_user_daily_summary_distances`.`fitbit_user_id` AS `fitbit_user_id`,`fitbit_user_daily_summary_distances`.`reported_on` AS `reported_on`,`fitbit_user_daily_summary_distances`.`activity` AS `activity`,`fitbit_user_daily_summary_distances`.`distance` AS `distance`,`fitbit_user_daily_summary_distances`.`created_at` AS `created_at`,`fitbit_user_daily_summary_distances`.`updated_at` AS `updated_at` from (((`fitbit_user_daily_summary_distances` join `fitbit_user_daily_summaries` on((`fitbit_user_daily_summaries`.`id` = `fitbit_user_daily_summary_distances`.`fitbit_user_daily_summary_id`))) join `fitbit_users` on((`fitbit_users`.`id` = `fitbit_user_daily_summaries`.`fitbit_user_id`))) join `apps` on((`apps`.`id` = `fitbit_users`.`app_id`))) where (`apps`.`database_user_name` = convert(substring_index(user(),_utf8'@',1) using latin1)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `fitbit_user_devices_view`
--

/*!50001 DROP VIEW IF EXISTS `fitbit_user_devices_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `fitbit_user_devices_view` AS select `fitbit_user_devices`.`id` AS `id`,`fitbit_user_devices`.`fitbit_user_id` AS `fitbit_user_id`,`fitbit_user_devices`.`remote_id` AS `remote_id`,`fitbit_user_devices`.`last_sync_time` AS `last_sync_time`,`fitbit_user_devices`.`type_of_device` AS `type_of_device`,`fitbit_user_devices`.`device_version` AS `device_version`,`fitbit_user_devices`.`battery` AS `battery`,`fitbit_user_devices`.`created_at` AS `created_at`,`fitbit_user_devices`.`updated_at` AS `updated_at` from ((`fitbit_user_devices` join `fitbit_users` on((`fitbit_users`.`id` = `fitbit_user_devices`.`fitbit_user_id`))) join `apps` on((`apps`.`id` = `fitbit_users`.`app_id`))) where (`apps`.`database_user_name` = convert(substring_index(user(),_utf8'@',1) using latin1)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `fitbit_users_view`
--

/*!50001 DROP VIEW IF EXISTS `fitbit_users_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `fitbit_users_view` AS select `fitbit_users`.`id` AS `id`,`fitbit_users`.`user_id` AS `user_id`,`fitbit_users`.`app_id` AS `app_id`,`fitbit_users`.`height_unit` AS `height_unit`,`fitbit_users`.`encoded_id` AS `encoded_id`,`fitbit_users`.`date_of_birth` AS `date_of_birth`,`fitbit_users`.`avatar` AS `avatar`,`fitbit_users`.`glucose_unit` AS `glucose_unit`,`fitbit_users`.`gender` AS `gender`,`fitbit_users`.`stride_length_running` AS `stride_length_running`,`fitbit_users`.`distance_unit` AS `distance_unit`,`fitbit_users`.`member_since` AS `member_since`,`fitbit_users`.`foods_locale` AS `foods_locale`,`fitbit_users`.`timezone` AS `timezone`,`fitbit_users`.`water_unit` AS `water_unit`,`fitbit_users`.`stride_length_walking` AS `stride_length_walking`,`fitbit_users`.`locale` AS `locale`,`fitbit_users`.`height` AS `height`,`fitbit_users`.`country` AS `country`,`fitbit_users`.`weight_unit` AS `weight_unit`,`fitbit_users`.`weight` AS `weight`,`fitbit_users`.`offset_from_utc_millis` AS `offset_from_utc_millis`,`fitbit_users`.`display_name` AS `display_name`,`fitbit_users`.`created_at` AS `created_at`,`fitbit_users`.`updated_at` AS `updated_at` from (`fitbit_users` join `apps` on((`apps`.`id` = `fitbit_users`.`app_id`))) where (`apps`.`database_user_name` = convert(substring_index(user(),_utf8'@',1) using latin1)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `garmin_oauth_tokens_view`
--

/*!50001 DROP VIEW IF EXISTS `garmin_oauth_tokens_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`hesdev`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `garmin_oauth_tokens_view` AS select `garmin_oauth_tokens`.`id` AS `id`,`garmin_oauth_tokens`.`app_id` AS `app_id`,`garmin_oauth_tokens`.`user_id` AS `user_id`,`garmin_oauth_tokens`.`token` AS `token`,`garmin_oauth_tokens`.`secret` AS `secret`,`garmin_oauth_tokens`.`extra_data` AS `extra_data`,`garmin_oauth_tokens`.`created_at` AS `created_at`,`garmin_oauth_tokens`.`updated_at` AS `updated_at` from (`garmin_oauth_tokens` join `apps` on((`apps`.`id` = `garmin_oauth_tokens`.`app_id`))) where (`apps`.`database_user_name` = convert(substring_index(user(),'@',1) using latin1)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `garmin_wellness_summaries_view`
--

/*!50001 DROP VIEW IF EXISTS `garmin_wellness_summaries_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`hesdev`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `garmin_wellness_summaries_view` AS select `garmin_wellness_summaries`.`id` AS `id`,`garmin_wellness_summaries`.`app_id` AS `app_id`,`garmin_wellness_summaries`.`user_id` AS `user_id`,`garmin_wellness_summaries`.`reported_on` AS `reported_on`,`garmin_wellness_summaries`.`steps` AS `steps`,`garmin_wellness_summaries`.`start_time` AS `start_time`,`garmin_wellness_summaries`.`duration_secs` AS `duration_secs`,`garmin_wellness_summaries`.`start_time_offset` AS `start_time_offset`,`garmin_wellness_summaries`.`active_secs` AS `active_secs`,`garmin_wellness_summaries`.`distance` AS `distance`,`garmin_wellness_summaries`.`activity_type` AS `activity_type`,`garmin_wellness_summaries`.`kcal` AS `kcal`,`garmin_wellness_summaries`.`voltage` AS `voltage`,`garmin_wellness_summaries`.`created_at` AS `created_at`,`garmin_wellness_summaries`.`updated_at` AS `updated_at` from (`garmin_wellness_summaries` join `apps` on((`apps`.`id` = `garmin_wellness_summaries`.`app_id`))) where (`apps`.`database_user_name` = convert(substring_index(user(),'@',1) using latin1)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `jawbone_move_data_view`
--

/*!50001 DROP VIEW IF EXISTS `jawbone_move_data_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `jawbone_move_data_view` AS select `jawbone_move_data`.`id` AS `id`,`jawbone_move_data`.`jawbone_user_id` AS `jawbone_user_id`,`jawbone_move_data`.`xid` AS `xid`,`jawbone_move_data`.`title` AS `title`,`jawbone_move_data`.`on_date` AS `on_date`,`jawbone_move_data`.`time_created` AS `time_created`,`jawbone_move_data`.`time_updated` AS `time_updated`,`jawbone_move_data`.`time_completed` AS `time_completed`,`jawbone_move_data`.`snapshot_image` AS `snapshot_image`,`jawbone_move_data`.`distance` AS `distance`,`jawbone_move_data`.`km` AS `km`,`jawbone_move_data`.`steps` AS `steps`,`jawbone_move_data`.`active_time` AS `active_time`,`jawbone_move_data`.`longest_active` AS `longest_active`,`jawbone_move_data`.`inactive_time` AS `inactive_time`,`jawbone_move_data`.`longest_idle` AS `longest_idle`,`jawbone_move_data`.`calories` AS `calories`,`jawbone_move_data`.`bmr_day` AS `bmr_day`,`jawbone_move_data`.`bmr` AS `bmr`,`jawbone_move_data`.`bg_calories` AS `bg_calories`,`jawbone_move_data`.`wo_calories` AS `wo_calories`,`jawbone_move_data`.`wo_time` AS `wo_time`,`jawbone_move_data`.`wo_active_time` AS `wo_active_time`,`jawbone_move_data`.`wo_count` AS `wo_count`,`jawbone_move_data`.`wo_longest` AS `wo_longest`,`jawbone_move_data`.`created_at` AS `created_at`,`jawbone_move_data`.`updated_at` AS `updated_at` from ((`jawbone_move_data` join `jawbone_users` on((`jawbone_users`.`id` = `jawbone_move_data`.`jawbone_user_id`))) join `apps` on((`apps`.`id` = `jawbone_users`.`app_id`))) where (`apps`.`database_user_name` = convert(substring_index(user(),_utf8'@',1) using latin1)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `jawbone_notifications_view`
--

/*!50001 DROP VIEW IF EXISTS `jawbone_notifications_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `jawbone_notifications_view` AS select `jawbone_notifications`.`id` AS `id`,`jawbone_notifications`.`jawbone_user_id` AS `jawbone_user_id`,`jawbone_notifications`.`user_xid` AS `user_xid`,`jawbone_notifications`.`event_xid` AS `event_xid`,`jawbone_notifications`.`action` AS `action`,`jawbone_notifications`.`event_type` AS `event_type`,`jawbone_notifications`.`status` AS `status`,`jawbone_notifications`.`created_at` AS `created_at`,`jawbone_notifications`.`updated_at` AS `updated_at` from ((`jawbone_notifications` join `jawbone_users` on((`jawbone_users`.`id` = `jawbone_notifications`.`jawbone_user_id`))) join `apps` on((`apps`.`id` = `jawbone_users`.`app_id`))) where (`apps`.`database_user_name` = convert(substring_index(user(),_utf8'@',1) using latin1)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `jawbone_oauth_tokens_view`
--

/*!50001 DROP VIEW IF EXISTS `jawbone_oauth_tokens_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `jawbone_oauth_tokens_view` AS select `jawbone_oauth_tokens`.`id` AS `id`,`jawbone_oauth_tokens`.`app_id` AS `app_id`,`jawbone_oauth_tokens`.`user_id` AS `user_id`,`jawbone_oauth_tokens`.`token` AS `token`,`jawbone_oauth_tokens`.`refresh_token` AS `refresh_token`,`jawbone_oauth_tokens`.`expiration_date` AS `expiration_date`,`jawbone_oauth_tokens`.`created_at` AS `created_at`,`jawbone_oauth_tokens`.`updated_at` AS `updated_at` from (`jawbone_oauth_tokens` join `apps` on((`apps`.`id` = `jawbone_oauth_tokens`.`app_id`))) where (`apps`.`database_user_name` = convert(substring_index(user(),_utf8'@',1) using latin1)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `jawbone_users_view`
--

/*!50001 DROP VIEW IF EXISTS `jawbone_users_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `jawbone_users_view` AS select `jawbone_users`.`id` AS `id`,`jawbone_users`.`user_id` AS `user_id`,`jawbone_users`.`app_id` AS `app_id`,`jawbone_users`.`xid` AS `xid`,`jawbone_users`.`first_name` AS `first_name`,`jawbone_users`.`last_name` AS `last_name`,`jawbone_users`.`image_url` AS `image_url`,`jawbone_users`.`weight` AS `weight`,`jawbone_users`.`height` AS `height`,`jawbone_users`.`created_at` AS `created_at`,`jawbone_users`.`updated_at` AS `updated_at`,`jawbone_users`.`last_sync` AS `last_sync` from (`jawbone_users` join `apps` on((`apps`.`id` = `jawbone_users`.`app_id`))) where (`apps`.`database_user_name` = convert(substring_index(user(),_utf8'@',1) using latin1)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `validic_history_view`
--

/*!50001 DROP VIEW IF EXISTS `validic_history_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`hesdev`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `validic_history_view` AS select `validic_history`.`id` AS `id`,`validic_history`.`validic_user_id` AS `validic_user_id`,`validic_history`.`user_id` AS `user_id`,`validic_history`.`app_id` AS `app_id`,`validic_history`.`reported_on` AS `reported_on`,`validic_history`.`is_processed` AS `is_processed`,`validic_history`.`created_at` AS `created_at`,`validic_history`.`updated_at` AS `updated_at` from (`validic_history` join `apps` on((`apps`.`id` = `validic_history`.`app_id`))) where (`apps`.`database_user_name` = convert(substring_index(user(),'@',1) using latin1)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2016-11-07 16:02:51
