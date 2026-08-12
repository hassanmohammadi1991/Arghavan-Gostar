<?php
/**
 * Security Helper Functions
 * Protection against SQL Injection, XSS, CSRF, and other vulnerabilities
 */

defined('TSR_SYSTEM') or define('TSR_SYSTEM', true);

require_once __DIR__ . '/../config/config.php';

class Security {
    
    /**
     * Generate CSRF token
     */
    public static function generateCSRFToken() {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
        
        $token = bin2hex(random_bytes(32));
        $_SESSION[SecurityConfig::CSRF_TOKEN_NAME] = $token;
        $_SESSION['csrf_token_time'] = time();
        
        return $token;
    }
    
    /**
     * Verify CSRF token
     */
    public static function verifyCSRFToken($token) {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
        
        if (!isset($_SESSION[SecurityConfig::CSRF_TOKEN_NAME])) {
            return false;
        }
        
        // Check token expiration
        if (isset($_SESSION['csrf_token_time']) && 
            (time() - $_SESSION['csrf_token_time']) > SecurityConfig::CSRF_TOKEN_EXPIRE) {
            unset($_SESSION[SecurityConfig::CSRF_TOKEN_NAME]);
            unset($_SESSION['csrf_token_time']);
            return false;
        }
        
        return hash_equals($_SESSION[SecurityConfig::CSRF_TOKEN_NAME], $token);
    }
    
    /**
     * Sanitize input data
     */
    public static function sanitize($data, $type = 'string') {
        if (is_array($data)) {
            return array_map([self::class, 'sanitize'], $data, array_fill(0, count($data), $type));
        }
        
        switch ($type) {
            case 'int':
                return filter_var($data, FILTER_SANITIZE_NUMBER_INT);
            
            case 'float':
                return filter_var($data, FILTER_SANITIZE_NUMBER_FLOAT, FILTER_FLAG_ALLOW_FRACTION);
            
            case 'email':
                return filter_var($data, FILTER_SANITIZE_EMAIL);
            
            case 'url':
                return filter_var($data, FILTER_SANITIZE_URL);
            
            case 'html':
                return self::sanitizeHTML($data);
            
            default:
                return self::sanitizeString($data);
        }
    }
    
    /**
     * Sanitize string
     */
    private static function sanitizeString($data) {
        $data = trim($data);
        $data = stripslashes($data);
        $data = htmlspecialchars($data, ENT_QUOTES | ENT_HTML5, 'UTF-8');
        
        // Limit length
        if (strlen($data) > SecurityConfig::MAX_INPUT_LENGTH) {
            $data = substr($data, 0, SecurityConfig::MAX_INPUT_LENGTH);
        }
        
        return $data;
    }
    
    /**
     * Sanitize HTML (allow limited tags)
     */
    private static function sanitizeHTML($data) {
        $allowedTags = '<p><br><strong><em><ul><ol><li><a>';
        $data = strip_tags($data, $allowedTags);
        
        // Limit length
        if (strlen($data) > SecurityConfig::MAX_TEXT_LENGTH) {
            $data = substr($data, 0, SecurityConfig::MAX_TEXT_LENGTH);
        }
        
        return $data;
    }
    
    /**
     * Escape output for HTML context
     */
    public static function escape($data) {
        if (is_array($data)) {
            return array_map([self::class, 'escape'], $data);
        }
        return htmlspecialchars($data, ENT_QUOTES | ENT_HTML5, 'UTF-8');
    }
    
    /**
     * Hash password
     */
    public static function hashPassword($password) {
        return password_hash($password, SecurityConfig::PASSWORD_ALGO, [
            'cost' => SecurityConfig::PASSWORD_COST
        ]);
    }
    
    /**
     * Verify password
     */
    public static function verifyPassword($password, $hash) {
        return password_verify($password, $hash);
    }
    
    /**
     * Generate secure random token
     */
    public static function generateToken($length = 32) {
        return bin2hex(random_bytes($length / 2));
    }
    
    /**
     * Validate file upload
     */
    public static function validateFileUpload($file, $allowedExtensions = null) {
        if (!isset($file) || $file['error'] !== UPLOAD_ERR_OK) {
            return ['valid' => false, 'message' => 'File upload error'];
        }
        
        // Check file size
        if ($file['size'] > AppConfig::MAX_FILE_SIZE) {
            return ['valid' => false, 'message' => 'File size exceeds limit'];
        }
        
        // Check extension
        $extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        $allowed = $allowedExtensions ?? AppConfig::ALLOWED_EXTENSIONS;
        
        if (!in_array($extension, $allowed)) {
            return ['valid' => false, 'message' => 'Invalid file type'];
        }
        
        // Check MIME type
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $mimeType = finfo_file($finfo, $file['tmp_name']);
        finfo_close($finfo);
        
        $allowedMimeTypes = [
            'image/jpeg',
            'image/png',
            'application/pdf',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'application/vnd.ms-excel',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        ];
        
        if (!in_array($mimeType, $allowedMimeTypes)) {
            return ['valid' => false, 'message' => 'Invalid MIME type'];
        }
        
        return ['valid' => true, 'message' => 'File is valid'];
    }
    
    /**
     * Secure session initialization
     */
    public static function initSecureSession() {
        if (session_status() === PHP_SESSION_NONE) {
            ini_set('session.name', SecurityConfig::SESSION_NAME);
            ini_set('session.use_strict_mode', SecurityConfig::SESSION_USE_STRICT ? '1' : '0');
            ini_set('session.cookie_httponly', SecurityConfig::SESSION_HTTP_ONLY ? '1' : '0');
            ini_set('session.cookie_secure', SecurityConfig::SESSION_SECURE ? '1' : '0');
            ini_set('session.use_only_cookies', '1');
            ini_set('session.gc_maxlifetime', SecurityConfig::SESSION_LIFETIME);
            
            session_start();
        }
    }
    
    /**
     * Regenerate session ID
     */
    public static function regenerateSession() {
        session_regenerate_id(true);
    }
    
    /**
     * Destroy session securely
     */
    public static function destroySession() {
        $_SESSION = [];
        
        if (ini_get("session.use_cookies")) {
            $params = session_get_cookie_params();
            setcookie(
                session_name(),
                '',
                time() - 42000,
                $params["path"],
                $params["domain"],
                $params["secure"],
                $params["httponly"]
            );
        }
        
        session_destroy();
    }
}
