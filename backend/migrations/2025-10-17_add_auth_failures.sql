-- Auth failures tracking table for progressive throttling and lockout
CREATE TABLE IF NOT EXISTS auth_failures (
  id INT AUTO_INCREMENT PRIMARY KEY,
  phone_number VARCHAR(20) NOT NULL,
  failed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ip_address VARCHAR(45) NULL,
  user_agent TEXT NULL,
  KEY idx_auth_failures_phone (phone_number),
  KEY idx_auth_failures_timestamp (failed_at)
) ENGINE=InnoDB;

