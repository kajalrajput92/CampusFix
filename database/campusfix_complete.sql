-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: campusfix_db
-- ------------------------------------------------------
-- Server version	8.0.43

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `complaint_assignments`
--

DROP TABLE IF EXISTS `complaint_assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `complaint_assignments` (
  `assignment_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `complaint_id` bigint unsigned NOT NULL,
  `staff_id` bigint unsigned NOT NULL,
  `assigned_by` bigint unsigned DEFAULT NULL,
  `assigned_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`assignment_id`),
  KEY `fk_assignment_complaint` (`complaint_id`),
  KEY `fk_assignment_staff` (`staff_id`),
  KEY `fk_assignment_admin` (`assigned_by`),
  CONSTRAINT `fk_assignment_admin` FOREIGN KEY (`assigned_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  CONSTRAINT `fk_assignment_complaint` FOREIGN KEY (`complaint_id`) REFERENCES `complaints` (`complaint_id`),
  CONSTRAINT `fk_assignment_staff` FOREIGN KEY (`staff_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `complaint_assignments`
--

LOCK TABLES `complaint_assignments` WRITE;
/*!40000 ALTER TABLE `complaint_assignments` DISABLE KEYS */;
INSERT INTO `complaint_assignments` VALUES (1,1,3,2,'2026-11-04 13:51:23'),(2,9,3,2,'2026-11-05 08:19:29'),(3,10,3,2,'2026-11-10 18:23:19'),(4,11,3,2,'2026-11-11 08:44:04');
/*!40000 ALTER TABLE `complaint_assignments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `complaint_images`
--

DROP TABLE IF EXISTS `complaint_images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `complaint_images` (
  `image_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `complaint_id` bigint unsigned NOT NULL,
  `image_path` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `uploaded_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`image_id`),
  KEY `fk_images_complaint` (`complaint_id`),
  CONSTRAINT `fk_images_complaint` FOREIGN KEY (`complaint_id`) REFERENCES `complaints` (`complaint_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `complaint_images`
--

LOCK TABLES `complaint_images` WRITE;
/*!40000 ALTER TABLE `complaint_images` DISABLE KEYS */;
INSERT INTO `complaint_images` VALUES (1,2,'storage/uploads/complaints/d2c53e23bed3a5c4aff2310a7d45ed9e.png','2026-11-05 06:32:10'),(2,3,'storage/uploads/complaints/d4df5343a9f4cfaf58125f82425ea79c.png','2026-11-05 06:39:07'),(3,4,'storage/uploads/complaints/46c381b33b72b6506bac2f099fb495f7.png','2026-11-05 06:40:57'),(4,5,'storage/uploads/complaints/0d273496c27a5840fc51632d72b459c4.png','2026-11-05 06:42:10'),(5,5,'storage/uploads/complaints/a7e5e978d4e30d430c6ce2d82b134c99.png','2026-11-05 06:42:10'),(6,5,'storage/uploads/complaints/fbe915938687ab249714d1e66ef44828.png','2026-11-05 06:42:10'),(7,7,'storage/uploads/complaints/90f6a83044847164f43a378a2c2af4eb.png','2026-11-05 06:45:16'),(8,8,'storage/uploads/complaints/d1ca230121fc161b3bc51d2d5a2fa1f8.png','2026-11-05 06:45:30'),(9,11,'storage/uploads/complaints/19f854891c1554b23895121a20460509.jpg','2026-11-11 08:20:29');
/*!40000 ALTER TABLE `complaint_images` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `complaint_priority_history`
--

DROP TABLE IF EXISTS `complaint_priority_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `complaint_priority_history` (
  `priority_history_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `complaint_id` bigint unsigned NOT NULL,
  `changed_by` bigint unsigned NOT NULL,
  `old_priority` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `new_priority` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `changed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`priority_history_id`),
  KEY `idx_priority_history_complaint` (`complaint_id`,`changed_at`),
  KEY `idx_priority_history_admin` (`changed_by`),
  CONSTRAINT `fk_priority_history_admin` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_priority_history_complaint` FOREIGN KEY (`complaint_id`) REFERENCES `complaints` (`complaint_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `complaint_priority_history`
--

LOCK TABLES `complaint_priority_history` WRITE;
/*!40000 ALTER TABLE `complaint_priority_history` DISABLE KEYS */;
INSERT INTO `complaint_priority_history` VALUES (1,11,2,'MEDIUM','HIGH','2026-11-11 08:43:03');
/*!40000 ALTER TABLE `complaint_priority_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `complaint_status_history`
--

DROP TABLE IF EXISTS `complaint_status_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `complaint_status_history` (
  `history_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `complaint_id` bigint unsigned NOT NULL,
  `changed_by` bigint unsigned DEFAULT NULL,
  `old_status` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `new_status` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `changed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`history_id`),
  KEY `fk_history_complaint` (`complaint_id`),
  KEY `fk_history_user` (`changed_by`),
  CONSTRAINT `fk_history_complaint` FOREIGN KEY (`complaint_id`) REFERENCES `complaints` (`complaint_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_history_user` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `complaint_status_history`
--

LOCK TABLES `complaint_status_history` WRITE;
/*!40000 ALTER TABLE `complaint_status_history` DISABLE KEYS */;
INSERT INTO `complaint_status_history` VALUES (1,1,1,NULL,'SUBMITTED','Complaint submitted by student.','2026-11-04 13:11:48'),(2,1,2,'SUBMITTED','ASSIGNED','Complaint assigned to staff.','2026-11-04 13:51:23'),(3,1,3,'ASSIGNED','IN_PROGRESS',NULL,'2026-11-04 14:34:33'),(4,1,3,'IN_PROGRESS','RESOLVED','Water leakage issue fixed. The damaged pipe was repaired and the affected floor was cleaned.','2026-11-04 14:35:20'),(5,2,1,NULL,'SUBMITTED','Complaint submitted by student.','2026-11-05 06:32:10'),(6,3,1,NULL,'SUBMITTED','Complaint submitted by student.','2026-11-05 06:39:07'),(7,4,1,NULL,'SUBMITTED','Complaint submitted by student.','2026-11-05 06:40:57'),(8,5,1,NULL,'SUBMITTED','Complaint submitted by student.','2026-11-05 06:42:10'),(9,6,1,NULL,'SUBMITTED','Complaint submitted by student.','2026-11-05 06:43:37'),(10,7,1,NULL,'SUBMITTED','Complaint submitted by student.','2026-11-05 06:45:16'),(11,8,1,NULL,'SUBMITTED','Complaint submitted by student.','2026-11-05 06:45:30'),(12,9,1,NULL,'SUBMITTED','Complaint submitted by student.','2026-11-05 08:14:33'),(13,9,2,'SUBMITTED','ASSIGNED','Complaint assigned to staff.','2026-11-05 08:19:29'),(14,9,3,'ASSIGNED','IN_PROGRESS',NULL,'2026-11-05 08:25:53'),(15,9,3,'IN_PROGRESS','RESOLVED','Electrical wiring issue has been repaired and tested successfully.','2026-11-05 08:28:39'),(16,10,6,NULL,'SUBMITTED','Complaint submitted by student.','2026-11-10 17:46:21'),(17,10,2,'SUBMITTED','UNDER_REVIEW','Admin reviewing issue','2026-11-10 18:22:12'),(18,10,2,'UNDER_REVIEW','ASSIGNED','Complaint assigned to staff.','2026-11-10 18:23:19'),(19,10,3,'ASSIGNED','IN_PROGRESS',NULL,'2026-11-10 18:23:32'),(20,10,3,'IN_PROGRESS','RESOLVED','done 👍','2026-11-10 18:23:42'),(21,11,6,NULL,'SUBMITTED','Complaint submitted by student.','2026-11-11 08:20:29'),(22,11,2,'SUBMITTED','UNDER_REVIEW',NULL,'2026-11-11 08:42:54'),(23,11,2,'UNDER_REVIEW','ASSIGNED','Complaint assigned to staff.','2026-11-11 08:44:04'),(24,11,3,'ASSIGNED','IN_PROGRESS',NULL,'2026-11-11 08:44:25'),(25,11,3,'IN_PROGRESS','RESOLVED','work completed','2026-11-11 08:44:47'),(26,11,2,'RESOLVED','CLOSED',NULL,'2026-11-11 08:47:16');
/*!40000 ALTER TABLE `complaint_status_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `complaints`
--

DROP TABLE IF EXISTS `complaints`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `complaints` (
  `complaint_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `complaint_number` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `student_id` bigint unsigned NOT NULL,
  `location_id` int unsigned NOT NULL,
  `department_id` int unsigned DEFAULT NULL,
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `category` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `priority` enum('LOW','MEDIUM','HIGH','URGENT') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'MEDIUM',
  `status` enum('SUBMITTED','UNDER_REVIEW','ASSIGNED','IN_PROGRESS','RESOLVED','CLOSED','REJECTED','REOPENED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'SUBMITTED',
  `resolution_notes` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `resolved_at` timestamp NULL DEFAULT NULL,
  `closed_at` timestamp NULL DEFAULT NULL,
  `due_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`complaint_id`),
  UNIQUE KEY `uq_complaint_number` (`complaint_number`),
  KEY `fk_complaints_location` (`location_id`),
  KEY `fk_complaints_department` (`department_id`),
  KEY `idx_complaints_student` (`student_id`),
  KEY `idx_complaints_status` (`status`),
  KEY `idx_complaints_created` (`created_at`),
  CONSTRAINT `fk_complaints_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`) ON DELETE SET NULL,
  CONSTRAINT `fk_complaints_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`location_id`),
  CONSTRAINT `fk_complaints_student` FOREIGN KEY (`student_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `complaints`
--

LOCK TABLES `complaints` WRITE;
/*!40000 ALTER TABLE `complaints` DISABLE KEYS */;
INSERT INTO `complaints` VALUES (1,'CF-000001',1,1,NULL,'Water Leakage in Academic Block','There is continuous water leakage near room A-101 on the ground floor. The floor is getting wet and may cause accidents.','Plumbing','HIGH','RESOLVED','Water leakage issue fixed. The damaged pipe was repaired and the affected floor was cleaned.','2026-11-04 13:11:48','2026-11-04 14:35:20','2026-11-04 14:35:20',NULL,NULL),(2,'CF-000002',1,1,NULL,'Broken Water Tap','Water tap is leaking continuously.','plumbing','HIGH','SUBMITTED',NULL,'2026-11-05 06:32:10','2026-11-05 06:32:10',NULL,NULL,NULL),(3,'CF-000003',1,1,NULL,'Broken Water Tap','Water tap is leaking continuously.','plumbing','HIGH','SUBMITTED',NULL,'2026-11-05 06:39:07','2026-11-05 06:39:07',NULL,NULL,NULL),(4,'CF-000004',1,1,NULL,'Broken Water Tap','Water tap is leaking continuously.','plumbing','HIGH','SUBMITTED',NULL,'2026-11-05 06:40:57','2026-11-05 06:40:57',NULL,NULL,NULL),(5,'CF-000005',1,1,NULL,'Broken Water Tap','Water tap is leaking continuously.','plumbing','HIGH','SUBMITTED',NULL,'2026-11-05 06:42:10','2026-11-05 06:42:10',NULL,NULL,NULL),(6,'CF-000006',1,1,NULL,'Broken Water Tap','Water tap is leaking continuously.','plumbing','HIGH','SUBMITTED',NULL,'2026-11-05 06:43:37','2026-11-05 06:43:37',NULL,NULL,NULL),(7,'CF-000007',1,1,NULL,'Broken Water Tap','Water tap is leaking continuously.','plumbing','HIGH','SUBMITTED',NULL,'2026-11-05 06:45:16','2026-11-05 06:45:16',NULL,NULL,NULL),(8,'CF-000008',1,1,NULL,'Broken Water Tap','Water tap is leaking continuously.','plumbing','HIGH','SUBMITTED',NULL,'2026-11-05 06:45:30','2026-11-05 06:45:30',NULL,NULL,NULL),(9,'CF-000009',1,1,1,'Automatic Notification Test','Testing automatic notification after complaint submission.','Electrical','MEDIUM','RESOLVED','Electrical wiring issue has been repaired and tested successfully.','2026-11-05 08:14:33','2026-11-05 08:28:39','2026-11-05 08:28:39',NULL,NULL),(10,'CF-000010',6,1,1,'bulb','na','electronic','MEDIUM','RESOLVED','done 👍','2026-11-10 17:46:21','2026-11-10 18:23:42','2026-11-10 18:23:42',NULL,NULL),(11,'CF-000011',6,1,1,'board','white board','cleaning','HIGH','CLOSED','work completed','2026-11-11 08:20:29','2026-11-11 08:47:16','2026-11-11 08:44:47','2026-11-11 08:47:16',NULL);
/*!40000 ALTER TABLE `complaints` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `departments`
--

DROP TABLE IF EXISTS `departments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `departments` (
  `department_id` int unsigned NOT NULL AUTO_INCREMENT,
  `department_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`department_id`),
  UNIQUE KEY `department_name` (`department_name`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `departments`
--

LOCK TABLES `departments` WRITE;
/*!40000 ALTER TABLE `departments` DISABLE KEYS */;
INSERT INTO `departments` VALUES (1,'Electrical Maintenance','Handles electrical repairs, wiring, power supply and maintenance issues across campus.','2026-11-04 17:01:19');
/*!40000 ALTER TABLE `departments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `feedback`
--

DROP TABLE IF EXISTS `feedback`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `feedback` (
  `feedback_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `complaint_id` bigint unsigned NOT NULL,
  `student_id` bigint unsigned NOT NULL,
  `rating` tinyint unsigned NOT NULL,
  `comments` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`feedback_id`),
  UNIQUE KEY `complaint_id` (`complaint_id`),
  KEY `fk_feedback_student` (`student_id`),
  CONSTRAINT `fk_feedback_complaint` FOREIGN KEY (`complaint_id`) REFERENCES `complaints` (`complaint_id`),
  CONSTRAINT `fk_feedback_student` FOREIGN KEY (`student_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `chk_feedback_rating` CHECK ((`rating` between 1 and 5))
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `feedback`
--

LOCK TABLES `feedback` WRITE;
/*!40000 ALTER TABLE `feedback` DISABLE KEYS */;
INSERT INTO `feedback` VALUES (1,1,1,5,'The issue was resolved properly. Good service.','2026-11-05 07:27:39');
/*!40000 ALTER TABLE `feedback` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `locations`
--

DROP TABLE IF EXISTS `locations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `locations` (
  `location_id` int unsigned NOT NULL AUTO_INCREMENT,
  `building_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `block_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `floor_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `room_number` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`location_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `locations`
--

LOCK TABLES `locations` WRITE;
/*!40000 ALTER TABLE `locations` DISABLE KEYS */;
INSERT INTO `locations` VALUES (1,'Academic Block','Block A','Ground Floor','A-101','Test location for CampusFix complaint API','2026-11-04 12:43:33'),(2,'Central Library','Block B','Second Floor','B-202','Central library reading and study section.','2026-11-05 04:21:34');
/*!40000 ALTER TABLE `locations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `notification_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `complaint_id` bigint unsigned DEFAULT NULL,
  `type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `message` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `read_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`notification_id`),
  KEY `idx_notifications_user_read_created` (`user_id`,`is_read`,`created_at`),
  KEY `idx_notifications_complaint` (`complaint_id`),
  CONSTRAINT `fk_notifications_complaint` FOREIGN KEY (`complaint_id`) REFERENCES `complaints` (`complaint_id`) ON DELETE SET NULL,
  CONSTRAINT `fk_notifications_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
INSERT INTO `notifications` VALUES (1,1,1,'COMPLAINT_UPDATE','Complaint Update','Your complaint CF-000001 has been updated.',1,'2026-11-05 07:50:48','2026-11-05 07:54:10'),(3,1,9,'COMPLAINT_SUBMITTED','Complaint Submitted','Your complaint CF-000009 has been submitted successfully.',0,'2026-11-05 08:14:33',NULL),(4,1,9,'COMPLAINT_ASSIGNED','Complaint Assigned','Your complaint CF-000009 has been assigned to a staff member.',0,'2026-11-05 08:19:29',NULL),(5,3,9,'NEW_ASSIGNMENT','New Complaint Assigned','Complaint CF-000009 - Automatic Notification Test has been assigned to you.',1,'2026-11-05 08:19:29','2026-11-10 18:15:16'),(6,1,9,'COMPLAINT_IN_PROGRESS','Complaint Work Started','Work has started on your complaint CF-000009.',0,'2026-11-05 08:25:53',NULL),(8,6,10,'COMPLAINT_SUBMITTED','Complaint Submitted','Your complaint CF-000010 has been submitted successfully.',1,'2026-11-10 17:46:21','2026-11-10 17:47:16'),(9,6,10,'COMPLAINT_ASSIGNED','Complaint Assigned','Your complaint CF-000010 has been assigned to a staff member.',0,'2026-11-10 18:23:19',NULL),(10,3,10,'NEW_ASSIGNMENT','New Complaint Assigned','Complaint CF-000010 - bulb has been assigned to you.',1,'2026-11-10 18:23:19','2026-11-10 18:23:29'),(11,6,10,'COMPLAINT_IN_PROGRESS','Complaint Work Started','Work has started on your complaint CF-000010.',0,'2026-11-10 18:23:32',NULL),(12,6,10,'COMPLAINT_RESOLVED','Complaint Resolved','Your complaint CF-000010 has been resolved successfully.',0,'2026-11-10 18:23:42',NULL),(13,6,11,'COMPLAINT_SUBMITTED','Complaint Submitted','Your complaint CF-000011 has been submitted successfully.',1,'2026-11-11 08:20:29','2026-11-11 08:30:27'),(14,6,11,'COMPLAINT_ASSIGNED','Complaint Assigned','Your complaint CF-000011 has been assigned to a staff member.',0,'2026-11-11 08:44:04',NULL),(15,3,11,'NEW_ASSIGNMENT','New Complaint Assigned','Complaint CF-000011 - board has been assigned to you.',1,'2026-11-11 08:44:04','2026-11-11 08:44:21'),(16,6,11,'COMPLAINT_IN_PROGRESS','Complaint Work Started','Work has started on your complaint CF-000011.',0,'2026-11-11 08:44:25',NULL),(17,6,11,'COMPLAINT_RESOLVED','Complaint Resolved','Your complaint CF-000011 has been resolved successfully.',0,'2026-11-11 08:44:47',NULL),(18,2,11,'NEW_COMPLAINT','New Complaint Submitted','Complaint CF-000011 (board) was submitted by student.',1,'2026-11-11 09:17:29','2026-11-11 09:17:51'),(19,2,10,'COMPLAINT_RESOLVED','Complaint Resolved','Complaint CF-000010 (bulb) has been marked as RESOLVED.',0,'2026-11-11 08:17:29',NULL),(20,2,9,'COMPLAINT_RESOLVED','Complaint Resolved','Complaint CF-000009 (Automatic Notification Test) has been marked as RESOLVED.',1,'2026-11-10 09:17:29',NULL),(21,2,1,'SYSTEM','CampusFix System Alert','Welcome to CampusFix Admin Console. All system services are active.',1,'2026-11-09 09:17:29',NULL);
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `password_resets`
--

DROP TABLE IF EXISTS `password_resets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `password_resets` (
  `reset_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `token_hash` char(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` datetime NOT NULL,
  `used_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`reset_id`),
  UNIQUE KEY `uq_password_reset_token` (`token_hash`),
  KEY `idx_password_reset_user` (`user_id`),
  KEY `idx_password_reset_expiry` (`expires_at`),
  CONSTRAINT `fk_password_reset_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `password_resets`
--

LOCK TABLES `password_resets` WRITE;
/*!40000 ALTER TABLE `password_resets` DISABLE KEYS */;
INSERT INTO `password_resets` VALUES (1,1,'1ef7b89629c6d0562c91a9b519913e66a99bc5193806c6b6ecc8e81ea46aa932','2026-11-05 11:39:13','2026-11-05 15:46:11','2026-11-05 10:09:13'),(2,1,'923a71e2ef17b9b783290ebf158acd9ee6357b971fb815314fdea2ab62ceaa93','2026-11-05 11:46:11','2026-11-05 16:18:47','2026-11-05 10:16:11'),(3,1,'8729e537ddc5e74f1c4b8cf23c16626c3dbb1d631439e0e0a630a9903b8eae73','2026-11-05 16:48:47','2026-11-05 16:19:23','2026-11-05 10:48:47');
/*!40000 ALTER TABLE `password_resets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `department_id` int unsigned DEFAULT NULL,
  `full_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `role` enum('STUDENT','STAFF','ADMIN') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'STUDENT',
  `enrollment_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `employee_id` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `token_version` int unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `enrollment_number` (`enrollment_number`),
  UNIQUE KEY `employee_id` (`employee_id`),
  KEY `fk_users_department` (`department_id`),
  CONSTRAINT `fk_users_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,NULL,'Test Student Updated','bossdkthe51@gmail.com','$2y$10$PwN5CBxtaO0ZJmgub4jGzO.Ixs43YUmrex8uDLen5jRZGO9yUa4ki','9876543210','STUDENT',NULL,NULL,1,'2026-11-04 12:13:41','2026-11-05 10:57:25',2),(2,NULL,'CampusFix Admin','admin@campusfix.com','$2y$10$Tc0nbe/S5yJ6cyTH19jiuug8RERBdBsfUQf.0cytz6mdhKPaXNkEe',NULL,'ADMIN',NULL,'CF-ADMIN-001',1,'2026-11-04 13:46:43','2026-11-11 09:18:04',5),(3,NULL,'CampusFix Staff','staff@campusfix.com','$2y$10$.jUUAKVAL4lkUGO8EqYqBercnWHWWh7dHV.ev6d5azM5mmZ43KHv6',NULL,'STAFF',NULL,'CF-STAFF-001',1,'2026-11-04 13:46:43','2026-11-10 19:02:10',1),(6,NULL,'Divyanshu Singh Chauhan','divyanshusinghchauhan58@gmail.com','$2y$10$MuCv2yyG/qUL3VhUP8yobOAtk7rs5k4/a/W.4AzjzMbm95BGWHxoe',NULL,'STUDENT',NULL,NULL,1,'2026-11-10 17:43:40','2026-11-11 08:41:20',3);
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

-- Dump completed on 2026-11-11 14:52:04
