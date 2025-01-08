CREATE TABLE `customers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customer_name` varchar(255) DEFAULT NULL,
  `customer_type` varchar(20) DEFAULT NULL,
  `status` varchar(15) DEFAULT NULL,
  `member_flag` tinyint(1) DEFAULT '0',
  `mobile_number` varchar(10) DEFAULT NULL,
  `short_name` varchar(10) DEFAULT NULL,
  `village_name` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_customers_customer_name` (`customer_name`)
) ENGINE=InnoDB AUTO_INCREMENT=1006 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
