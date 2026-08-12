<?php
/**
 * Database Configuration for TSR System
 * Production-ready configuration with environment-based settings
 */

// Prevent direct access
defined('TSR_SYSTEM') or define('TSR_SYSTEM', true);

class DatabaseConfig {
    // Database credentials
    const DB_HOST = 'localhost';
    const DB_NAME = 'tsr_system';
    const DB_USER = 'root';
    const DB_PASS = ''; // Change in production
    
    // Database connection settings
    const DB_CHARSET = 'utf8mb4';
    const DB_COLLATE = 'utf8mb4_unicode_ci';
    
    // Connection options
    const DB_PERSISTENT = false;
    const DB_ERROR_MODE = PDO::ERRMODE_EXCEPTION;
}

/**
 * Application Configuration
 */
class AppConfig {
    // Application settings
    const APP_NAME = 'TSR Management System';
    const APP_VERSION = '1.0.0';
    const APP_ENV = 'development'; // Change to 'production' in production
    
    // Security settings
    const SESSION_LIFETIME = 3600; // 1 hour
    const PASSWORD_MIN_LENGTH = 8;
    const MAX_LOGIN_ATTEMPTS = 5;
    const LOCKOUT_TIME = 900; // 15 minutes
    
    // File upload settings
    const MAX_FILE_SIZE = 5242880; // 5MB
    const ALLOWED_EXTENSIONS = ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'xls', 'xlsx'];
    const UPLOAD_DIR = __DIR__ . '/../uploads/';
    
    // Pagination
    const ITEMS_PER_PAGE = 20;
    
    // Date format
    const DATE_FORMAT = 'Y-m-d H:i:s';
    const DISPLAY_DATE_FORMAT = 'd/m/Y H:i';
}

/**
 * Security Configuration
 */
class SecurityConfig {
    // CSRF token settings
    const CSRF_TOKEN_NAME = 'csrf_token';
    const CSRF_TOKEN_EXPIRE = 3600;
    
    // Session settings
    const SESSION_NAME = 'TSR_SESSION';
    const SESSION_SECURE = false; // Set to true in production with HTTPS
    const SESSION_HTTP_ONLY = true;
    const SESSION_USE_STRICT = true;
    
    // Password hashing
    const PASSWORD_ALGO = PASSWORD_BCRYPT;
    const PASSWORD_COST = 12;
    
    // Input sanitization
    const MAX_INPUT_LENGTH = 10000;
    const MAX_TEXT_LENGTH = 5000;
}
