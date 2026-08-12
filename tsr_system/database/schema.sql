-- TSR System Database Schema
-- Production-ready schema with proper indexing and relationships

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

-- Create database
CREATE DATABASE IF NOT EXISTS `tsr_system` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `tsr_system`;

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE `users` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `personnel_code` VARCHAR(50) NOT NULL UNIQUE,
  `first_name` VARCHAR(100) NOT NULL,
  `last_name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(255) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `job_group_id` INT(11) UNSIGNED DEFAULT NULL,
  `job_position_id` INT(11) UNSIGNED DEFAULT NULL,
  `role` ENUM('user', 'supervisor', 'manager', 'admin') NOT NULL DEFAULT 'user',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `login_attempts` INT(11) NOT NULL DEFAULT 0,
  `locked_until` DATETIME DEFAULT NULL,
  `last_login` DATETIME DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_personnel_code` (`personnel_code`),
  KEY `idx_email` (`email`),
  KEY `idx_job_group` (`job_group_id`),
  KEY `idx_job_position` (`job_position_id`),
  KEY `idx_role` (`role`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- JOB GROUPS TABLE
-- ============================================
CREATE TABLE `job_groups` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_name` (`name`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- JOB POSITIONS TABLE
-- ============================================
CREATE TABLE `job_positions` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_name` (`name`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- WORKFLOW STATES TABLE
-- ============================================
CREATE TABLE `workflow_states` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `code` VARCHAR(50) NOT NULL UNIQUE,
  `description` TEXT DEFAULT NULL,
  `color` VARCHAR(20) DEFAULT '#6c757d',
  `icon` VARCHAR(50) DEFAULT 'fa-circle',
  `sort_order` INT(11) NOT NULL DEFAULT 0,
  `is_initial` TINYINT(1) NOT NULL DEFAULT 0,
  `is_final` TINYINT(1) NOT NULL DEFAULT 0,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_code` (`code`),
  KEY `idx_sort_order` (`sort_order`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- WORKFLOW TRANSITIONS TABLE
-- ============================================
CREATE TABLE `workflow_transitions` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `from_state_id` INT(11) UNSIGNED NOT NULL,
  `to_state_id` INT(11) UNSIGNED NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `required_role` ENUM('user', 'supervisor', 'manager', 'admin') DEFAULT NULL,
  `requires_approval` TINYINT(1) NOT NULL DEFAULT 0,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_from_state` (`from_state_id`),
  KEY `idx_to_state` (`to_state_id`),
  KEY `idx_is_active` (`is_active`),
  CONSTRAINT `fk_transition_from_state` FOREIGN KEY (`from_state_id`) REFERENCES `workflow_states`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_transition_to_state` FOREIGN KEY (`to_state_id`) REFERENCES `workflow_states`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TSR REQUESTS TABLE
-- ============================================
CREATE TABLE `tsr_requests` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `request_number` VARCHAR(50) NOT NULL UNIQUE,
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT NOT NULL,
  `requester_id` INT(11) UNSIGNED NOT NULL,
  `current_state_id` INT(11) UNSIGNED NOT NULL,
  `priority` ENUM('low', 'medium', 'high', 'critical') NOT NULL DEFAULT 'medium',
  `category` VARCHAR(100) DEFAULT NULL,
  `location` VARCHAR(255) DEFAULT NULL,
  `equipment_id` INT(11) UNSIGNED DEFAULT NULL,
  `assigned_to` INT(11) UNSIGNED DEFAULT NULL,
  `due_date` DATETIME DEFAULT NULL,
  `completed_at` DATETIME DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_request_number` (`request_number`),
  KEY `idx_requester` (`requester_id`),
  KEY `idx_current_state` (`current_state_id`),
  KEY `idx_priority` (`priority`),
  KEY `idx_assigned_to` (`assigned_to`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_request_requester` FOREIGN KEY (`requester_id`) REFERENCES `users`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_request_current_state` FOREIGN KEY (`current_state_id`) REFERENCES `workflow_states`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_request_assigned_to` FOREIGN KEY (`assigned_to`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TSR REQUEST HISTORY TABLE
-- ============================================
CREATE TABLE `tsr_request_history` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `request_id` INT(11) UNSIGNED NOT NULL,
  `from_state_id` INT(11) UNSIGNED DEFAULT NULL,
  `to_state_id` INT(11) UNSIGNED NOT NULL,
  `transition_id` INT(11) UNSIGNED DEFAULT NULL,
  `user_id` INT(11) UNSIGNED NOT NULL,
  `action_type` ENUM('create', 'transition', 'update', 'comment', 'attachment') NOT NULL,
  `comments` TEXT DEFAULT NULL,
  `metadata` JSON DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_request` (`request_id`),
  KEY `idx_from_state` (`from_state_id`),
  KEY `idx_to_state` (`to_state_id`),
  KEY `idx_user` (`user_id`),
  KEY `idx_action_type` (`action_type`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_history_request` FOREIGN KEY (`request_id`) REFERENCES `tsr_requests`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_history_from_state` FOREIGN KEY (`from_state_id`) REFERENCES `workflow_states`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_history_to_state` FOREIGN KEY (`to_state_id`) REFERENCES `workflow_states`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_history_transition` FOREIGN KEY (`transition_id`) REFERENCES `workflow_transitions`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_history_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- DYNAMIC FORM FIELDS TABLE
-- ============================================
CREATE TABLE `form_fields` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `field_name` VARCHAR(100) NOT NULL,
  `field_label` VARCHAR(255) NOT NULL,
  `field_type` ENUM('text', 'textarea', 'number', 'date', 'datetime', 'select', 'multiselect', 'checkbox', 'radio', 'file') NOT NULL,
  `field_options` JSON DEFAULT NULL,
  `is_required` TINYINT(1) NOT NULL DEFAULT 0,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `sort_order` INT(11) NOT NULL DEFAULT 0,
  `validation_rules` JSON DEFAULT NULL,
  `default_value` VARCHAR(255) DEFAULT NULL,
  `placeholder` VARCHAR(255) DEFAULT NULL,
  `help_text` TEXT DEFAULT NULL,
  `icon` VARCHAR(50) DEFAULT NULL,
  `section` VARCHAR(100) DEFAULT NULL,
  `visible_roles` JSON DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_field_name` (`field_name`),
  KEY `idx_field_type` (`field_type`),
  KEY `idx_is_active` (`is_active`),
  KEY `idx_sort_order` (`sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TSR CUSTOM FIELDS DATA TABLE
-- ============================================
CREATE TABLE `tsr_request_custom_fields` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `request_id` INT(11) UNSIGNED NOT NULL,
  `field_id` INT(11) UNSIGNED NOT NULL,
  `field_value` TEXT DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_request_field` (`request_id`, `field_id`),
  KEY `idx_request` (`request_id`),
  KEY `idx_field` (`field_id`),
  CONSTRAINT `fk_custom_request` FOREIGN KEY (`request_id`) REFERENCES `tsr_requests`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_custom_field` FOREIGN KEY (`field_id`) REFERENCES `form_fields`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- ATTACHMENTS TABLE
-- ============================================
CREATE TABLE `attachments` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `request_id` INT(11) UNSIGNED NOT NULL,
  `user_id` INT(11) UNSIGNED NOT NULL,
  `file_name` VARCHAR(255) NOT NULL,
  `file_path` VARCHAR(500) NOT NULL,
  `file_size` INT(11) NOT NULL,
  `file_type` VARCHAR(100) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_request` (`request_id`),
  KEY `idx_user` (`user_id`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_attachment_request` FOREIGN KEY (`request_id`) REFERENCES `tsr_requests`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_attachment_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- PERMISSIONS TABLE
-- ============================================
CREATE TABLE `permissions` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `code` VARCHAR(50) NOT NULL UNIQUE,
  `description` TEXT DEFAULT NULL,
  `module` VARCHAR(50) NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_code` (`code`),
  KEY `idx_module` (`module`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- ROLE PERMISSIONS TABLE
-- ============================================
CREATE TABLE `role_permissions` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `role` ENUM('user', 'supervisor', 'manager', 'admin') NOT NULL,
  `permission_id` INT(11) UNSIGNED NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_role_permission` (`role`, `permission_id`),
  KEY `idx_role` (`role`),
  KEY `idx_permission` (`permission_id`),
  CONSTRAINT `fk_role_permission` FOREIGN KEY (`permission_id`) REFERENCES `permissions`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- SYSTEM SETTINGS TABLE
-- ============================================
CREATE TABLE `system_settings` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `setting_key` VARCHAR(100) NOT NULL UNIQUE,
  `setting_value` TEXT DEFAULT NULL,
  `setting_type` ENUM('string', 'number', 'boolean', 'json') NOT NULL DEFAULT 'string',
  `description` TEXT DEFAULT NULL,
  `is_editable` TINYINT(1) NOT NULL DEFAULT 1,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_setting_key` (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- AUDIT LOG TABLE
-- ============================================
CREATE TABLE `audit_log` (
  `id` BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT(11) UNSIGNED DEFAULT NULL,
  `action` VARCHAR(100) NOT NULL,
  `table_name` VARCHAR(100) DEFAULT NULL,
  `record_id` INT(11) DEFAULT NULL,
  `old_values` JSON DEFAULT NULL,
  `new_values` JSON DEFAULT NULL,
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `user_agent` VARCHAR(255) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user` (`user_id`),
  KEY `idx_action` (`action`),
  KEY `idx_table` (`table_name`),
  KEY `idx_record` (`record_id`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_audit_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- INITIAL DATA
-- ============================================

-- Insert default job groups
INSERT INTO `job_groups` (`name`, `description`) VALUES
('فنی و مهندسی', 'گروه فنی و مهندسی'),
('عملیات و تولید', 'گروه عملیات و تولید'),
('نگهداری و تعمیرات', 'گروه نگهداری و تعمیرات'),
('اداری و پشتیبانی', 'گروه اداری و پشتیبانی'),
('مدیریت', 'گروه مدیریت');

-- Insert default job positions
INSERT INTO `job_positions` (`name`, `description`) VALUES
('تکنسین', 'تکنسین فنی'),
('کارشناس', 'کارشناس فنی'),
('سرپرست', 'سرپرست بخش'),
('مدیر', 'مدیر بخش'),
('اپراتور', 'اپراتور تولید');

-- Insert default workflow states
INSERT INTO `workflow_states` (`name`, `code`, `description`, `color`, `icon`, `sort_order`, `is_initial`, `is_final`) VALUES
('پیش‌نویس', 'draft', 'درخواست در حالت پیش‌نویس', '#6c757d', 'fa-file', 1, 1, 0),
('ثبت شده', 'submitted', 'درخواست ثبت شده است', '#007bff', 'fa-paper-plane', 2, 0, 0),
('در حال بررسی', 'under_review', 'در حال بررسی توسط سرپرست', '#ffc107', 'fa-eye', 3, 0, 0),
('تایید شده', 'approved', 'درخواست تایید شده است', '#28a745', 'fa-check-circle', 4, 0, 0),
('رد شده', 'rejected', 'درخواست رد شده است', '#dc3545', 'fa-times-circle', 5, 0, 1),
('در حال اجرا', 'in_progress', 'در حال انجام کار', '#17a2b8', 'fa-cog', 6, 0, 0),
('تکمیل شده', 'completed', 'درخواست تکمیل شده است', '#28a745', 'fa-check-double', 7, 0, 1);

-- Insert default workflow transitions
INSERT INTO `workflow_transitions` (`from_state_id`, `to_state_id`, `name`, `required_role`, `requires_approval`) VALUES
(1, 2, 'ثبت درخواست', 'user', 0),
(2, 3, 'بررسی اولیه', 'supervisor', 0),
(3, 4, 'تایید درخواست', 'supervisor', 1),
(3, 5, 'رد درخواست', 'supervisor', 1),
(4, 6, 'شروع اجرا', 'manager', 0),
(6, 7, 'تکمیل کار', 'user', 0),
(7, 2, 'بازگشت به بررسی', 'supervisor', 0);

-- Insert default form fields
INSERT INTO `form_fields` (`field_name`, `field_label`, `field_type`, `is_required`, `sort_order`, `icon`, `section`) VALUES
('title', 'عنوان درخواست', 'text', 1, 1, 'fa-heading', 'general'),
('description', 'شرح درخواست', 'textarea', 1, 2, 'fa-align-left', 'general'),
('priority', 'اولویت', 'select', 1, 3, 'fa-exclamation-triangle', 'general'),
('category', 'دسته‌بندی', 'select', 1, 4, 'fa-folder', 'general'),
('location', 'محل', 'text', 0, 5, 'fa-map-marker-alt', 'location'),
('equipment_id', 'تجهیزات', 'select', 0, 6, 'fa-cogs', 'equipment'),
('due_date', 'تاریخ سررسید', 'date', 0, 7, 'fa-calendar', 'timing');

-- Insert default permissions
INSERT INTO `permissions` (`name`, `code`, `description`, `module`) VALUES
('مشاهده درخواست‌ها', 'view_requests', 'امکان مشاهده لیست درخواست‌ها', 'tsr'),
('ایجاد درخواست', 'create_request', 'امکان ایجاد درخواست جدید', 'tsr'),
('ویرایش درخواست', 'edit_request', 'امکان ویرایش درخواست', 'tsr'),
('حذف درخواست', 'delete_request', 'امکان حذف درخواست', 'tsr'),
('تایید درخواست', 'approve_request', 'امکان تایید درخواست', 'workflow'),
('رد درخواست', 'reject_request', 'امکان رد درخواست', 'workflow'),
('مدیریت کاربران', 'manage_users', 'امکان مدیریت کاربران', 'admin'),
('مدیریت تنظیمات', 'manage_settings', 'امکان مدیریت تنظیمات سیستم', 'admin'),
('خروجی اکسل', 'export_excel', 'امکان خروجی اکسل', 'reports'),
('مشاهده داشبورد', 'view_dashboard', 'امکان مشاهده داشبورد', 'dashboard');

-- Insert default role permissions
INSERT INTO `role_permissions` (`role`, `permission_id`) 
SELECT 'user', id FROM permissions WHERE code IN ('view_requests', 'create_request', 'view_dashboard');

INSERT INTO `role_permissions` (`role`, `permission_id`) 
SELECT 'supervisor', id FROM permissions WHERE code IN ('view_requests', 'create_request', 'edit_request', 'approve_request', 'reject_request', 'view_dashboard');

INSERT INTO `role_permissions` (`role`, `permission_id`) 
SELECT 'manager', id FROM permissions WHERE code IN ('view_requests', 'create_request', 'edit_request', 'approve_request', 'reject_request', 'view_dashboard');

INSERT INTO `role_permissions` (`role`, `permission_id`) 
SELECT 'admin', id FROM permissions;

-- Insert default system settings
INSERT INTO `system_settings` (`setting_key`, `setting_value`, `setting_type`, `description`, `is_editable`) VALUES
('app_name', 'سیستم مدیریت درخواست‌های فنی', 'string', 'نام نمایشی برنامه', 1),
('items_per_page', '20', 'number', 'تعداد آیتم‌ها در هر صفحه', 1),
('allow_file_upload', 'true', 'boolean', 'امکان آپلود فایل', 1),
('max_file_size_mb', '5', 'number', 'حداکثر حجم فایل (مگابایت)', 1),
('session_timeout', '3600', 'number', 'زمان انقضای جلسه (ثانیه)', 1),
('require_email_verification', 'false', 'boolean', 'نیاز به تایید ایمیل', 0),
('default_language', 'fa', 'string', 'زبان پیش‌فرض', 1);

COMMIT;
