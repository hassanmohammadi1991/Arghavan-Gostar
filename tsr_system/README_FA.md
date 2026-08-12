# مستندات جامع سیستم مدیریت درخواست‌های فنی (TSR)

## فهرست مطالب

1. [معماری پایگاه داده](#1-معماری-پایگاه-داده)
2. [معماری سیستم](#2-معماری-سیستم)
3. [ساختار فنی](#3-ساختار-فنی)
4. [پانل مدیریتی](#4-پانل-مدیریتی)
5. [جزئیات فنی اجرایی](#5-جزئیات-فنی-اجرایی)
6. [امنیت](#6-امنیت)
7. [رابط کاربری](#7-رابط-کاربری)
8. [تست و مستندات](#8-تست-و-مستندات)

---

## 1. معماری پایگاه داده

### 1.1 جداول اصلی

#### **جدول users (کاربران)**
```sql
users (
  id,                    -- شناسه یکتا
  personnel_code,        -- کد پرسنلی (یکتا)
  first_name,            -- نام
  last_name,             -- نام خانوادگی
  email,                 -- ایمیل (یکتا)
  password_hash,         -- هش رمز عبور
  job_group_id,          -- گروه شغلی (FK)
  job_position_id,       -- سمت شغلی (FK)
  role,                  -- نقش: user, supervisor, manager, admin
  is_active,             -- وضعیت فعال بودن
  login_attempts,        -- تعداد تلاش‌های ناموفق
  locked_until,          -- زمان قفل شدن
  last_login,            -- آخرین ورود
  created_at,            -- تاریخ ایجاد
  updated_at             -- تاریخ به‌روزرسانی
)
```

**شاخص‌ها (Indexes):**
- `idx_personnel_code`: جستجوی سریع بر اساس کد پرسنلی
- `idx_email`: جستجوی سریع بر اساس ایمیل
- `idx_job_group`: فیلتر بر اساس گروه شغلی
- `idx_job_position`: فیلتر بر اساس سمت شغلی
- `idx_role`: فیلتر بر اساس نقش
- `idx_is_active`: فیلتر کاربران فعال

**روابط:**
- هر کاربر متعلق به یک گروه شغلی است (Many-to-One)
- هر کاربر دارای یک سمت شغلی است (Many-to-One)
- هر کاربر می‌تواند چندین درخواست TSR ایجاد کند (One-to-Many)

---

#### **جدول job_groups (گروه‌های شغلی)**
```sql
job_groups (
  id,                    -- شناسه یکتا
  name,                  -- نام گروه
  description,           -- توضیحات
  is_active,             -- وضعیت فعال بودن
  created_at,            -- تاریخ ایجاد
  updated_at             -- تاریخ به‌روزرسانی
)
```

**گروه‌های پیش‌فرض:**
- فنی و مهندسی
- عملیات و تولید
- نگهداری و تعمیرات
- اداری و پشتیبانی
- مدیریت

---

#### **جدول job_positions (سمت‌های شغلی)**
```sql
job_positions (
  id,                    -- شناسه یکتا
  name,                  -- نام سمت
  description,           -- توضیحات
  is_active,             -- وضعیت فعال بودن
  created_at,            -- تاریخ ایجاد
  updated_at             -- تاریخ به‌روزرسانی
)
```

**سمت‌های پیش‌فرض:**
- تکنسین
- کارشناس
- سرپرست
- مدیر
- اپراتور

---

#### **جدول workflow_states (وضعیت‌های جریان کار)**
```sql
workflow_states (
  id,                    -- شناسه یکتا
  name,                  -- نام وضعیت (فارسی)
  code,                  -- کد یکتا (انگلیسی)
  description,           -- توضیحات
  color,                 -- رنگ نمایشی
  icon,                  -- آیکون Font Awesome
  sort_order,            -- ترتیب نمایش
  is_initial,            -- وضعیت اولیه
  is_final,              -- وضعیت نهایی
  is_active,             -- وضعیت فعال بودن
  created_at,            -- تاریخ ایجاد
  updated_at             -- تاریخ به‌روزرسانی
)
```

**وضعیت‌های پیش‌فرض:**
1. پیش‌نویس (draft) - خاکستری
2. ثبت شده (submitted) - آبی
3. در حال بررسی (under_review) - زرد
4. تایید شده (approved) - سبز
5. رد شده (rejected) - قرمز
6. در حال اجرا (in_progress) - فیروزه‌ای
7. تکمیل شده (completed) - سبز تیره

---

#### **جدول workflow_transitions (انتقال‌های جریان کار)**
```sql
workflow_transitions (
  id,                    -- شناسه یکتا
  from_state_id,         -- وضعیت مبدأ (FK)
  to_state_id,           -- وضعیت مقصد (FK)
  name,                  -- نام انتقال
  required_role,         -- نقش مورد نیاز
  requires_approval,     -- نیاز به تایید
  is_active,             -- وضعیت فعال بودن
  created_at,            -- تاریخ ایجاد
  updated_at             -- تاریخ به‌روزرسانی
)
```

**انتقال‌های پیش‌فرض:**
- پیش‌نویس → ثبت شده (توسط کاربر)
- ثبت شده → در حال بررسی (توسط سرپرست)
- در حال بررسی → تایید شده (توسط سرپرست)
- در حال بررسی → رد شده (توسط سرپرست)
- تایید شده → در حال اجرا (توسط مدیر)
- در حال اجرا → تکمیل شده (توسط کاربر)
- تکمیل شده → ثبت شده (بازگشت به بررسی)

---

#### **جدول tsr_requests (درخواست‌های TSR)**
```sql
tsr_requests (
  id,                    -- شناسه یکتا
  request_number,        -- شماره درخواست (یکتا)
  title,                 -- عنوان
  description,           -- شرح
  requester_id,          -- درخواست‌دهنده (FK)
  current_state_id,      -- وضعیت فعلی (FK)
  priority,              -- اولویت: low, medium, high, critical
  category,              -- دسته‌بندی
  location,              -- محل
  equipment_id,          -- تجهیزات (FK)
  assigned_to,           -- محول شده به (FK)
  due_date,              -- تاریخ سررسید
  completed_at,          -- تاریخ تکمیل
  created_at,            -- تاریخ ایجاد
  updated_at             -- تاریخ به‌روزرسانی
)
```

**شاخص‌ها:**
- `idx_request_number`: جستجوی سریع شماره درخواست
- `idx_requester`: فیلتر بر اساس درخواست‌دهنده
- `idx_current_state`: فیلتر بر اساس وضعیت
- `idx_priority`: فیلتر بر اساس اولویت
- `idx_assigned_to`: فیلتر بر اساس مسئول اجرا
- `idx_created_at`: مرتب‌سازی بر اساس تاریخ

---

#### **جدول tsr_request_history (تاریخچه درخواست‌ها)**
```sql
tsr_request_history (
  id,                    -- شناسه یکتا
  request_id,            -- درخواست (FK)
  from_state_id,         -- وضعیت مبدأ (FK)
  to_state_id,           -- وضعیت مقصد (FK)
  transition_id,         -- انتقال (FK)
  user_id,               -- کاربر انجام‌دهنده (FK)
  action_type,           -- نوع اقدام: create, transition, update, comment, attachment
  comments,              -- نظرات
  metadata,              -- داده‌های اضافی (JSON)
  created_at             -- تاریخ ایجاد
)
```

**کاربردها:**
- ردیابی کامل گردش کار
- ثبت تمام تغییرات وضعیت
- ذخیره نظرات و توضیحات
- امکان گزارش‌گیری از تاریخچه

---

#### **جدول form_fields (فیلدهای پویای فرم)**
```sql
form_fields (
  id,                    -- شناسه یکتا
  field_name,            -- نام فیلد (انگلیسی)
  field_label,           -- برچسب فیلد (فارسی)
  field_type,            -- نوع: text, textarea, number, date, datetime, select, multiselect, checkbox, radio, file
  field_options,         -- گزینه‌ها (JSON)
  is_required,           -- اجباری بودن
  is_active,             -- وضعیت فعال بودن
  sort_order,            -- ترتیب نمایش
  validation_rules,      -- قوانین اعتبارسنجی (JSON)
  default_value,         -- مقدار پیش‌فرض
  placeholder,           -- متن جایگزین
  help_text,             -- متن راهنما
  icon,                  -- آیکون
  section,               -- بخش
  visible_roles,         -- نقش‌های مجاز مشاهده (JSON)
  created_at,            -- تاریخ ایجاد
  updated_at             -- تاریخ به‌روزرسانی
)
```

**ویژگی کلیدی:** این جدول امکان مدیریت پویای فرم‌ها بدون نیاز به تغییر کد را فراهم می‌کند.

---

#### **جدول tsr_request_custom_fields (داده‌های فیلدهای سفارشی)**
```sql
tsr_request_custom_fields (
  id,                    -- شناسه یکتا
  request_id,            -- درخواست (FK)
  field_id,              -- فیلد (FK)
  field_value,           -- مقدار فیلد
  created_at,            -- تاریخ ایجاد
  updated_at             -- تاریخ به‌روزرسانی
)
```

**کاربرد:** ذخیره مقادیر فیلدهای پویا برای هر درخواست

---

#### **جدول attachments (پیوست‌ها)**
```sql
attachments (
  id,                    -- شناسه یکتا
  request_id,            -- درخواست (FK)
  user_id,               -- آپلود کننده (FK)
  file_name,             -- نام فایل
  file_path,             -- مسیر فایل
  file_size,             -- حجم فایل
  file_type,             -- نوع فایل
  description,           -- توضیحات
  created_at             -- تاریخ ایجاد
)
```

---

#### **جدول permissions (مجوزها)**
```sql
permissions (
  id,                    -- شناسه یکتا
  name,                  -- نام مجوز
  code,                  -- کد یکتا
  description,           -- توضیحات
  module,                -- ماژول: tsr, workflow, admin, reports, dashboard
  created_at             -- تاریخ ایجاد
)
```

---

#### **جدول role_permissions (مجوزهای نقش‌ها)**
```sql
role_permissions (
  id,                    -- شناسه یکتا
  role,                  -- نقش: user, supervisor, manager, admin
  permission_id,         -- مجوز (FK)
  created_at             -- تاریخ ایجاد
)
```

**مجوزهای پیش‌فرض:**
- **user:** view_requests, create_request, view_dashboard
- **supervisor:** + edit_request, approve_request, reject_request
- **manager:** + approve_request
- **admin:** تمام مجوزها

---

#### **جدول system_settings (تنظیمات سیستم)**
```sql
system_settings (
  id,                    -- شناسه یکتا
  setting_key,           -- کلید تنظیمات (یکتا)
  setting_value,         -- مقدار
  setting_type,          -- نوع: string, number, boolean, json
  description,           -- توضیحات
  is_editable,           -- قابل ویرایش بودن
  updated_at             -- تاریخ به‌روزرسانی
)
```

**تنظیمات پیش‌فرض:**
- app_name: نام برنامه
- items_per_page: تعداد آیتم در هر صفحه
- allow_file_upload: امکان آپلود فایل
- max_file_size_mb: حداکثر حجم فایل
- session_timeout: زمان انقضای جلسه
- default_language: زبان پیش‌فرض

---

#### **جدول audit_log (لاک حسابرسی)**
```sql
audit_log (
  id,                    -- شناسه یکتا
  user_id,               -- کاربر (FK)
  action,                -- اقدام
  table_name,            -- نام جدول
  record_id,             -- شناسه رکورد
  old_values,            -- مقادیر قدیمی (JSON)
  new_values,            -- مقادیر جدید (JSON)
  ip_address,            -- آدرس IP
  user_agent,            -- مرورگر
  created_at             -- تاریخ ایجاد
)
```

**کاربرد:** ثبت تمام تغییرات مهم برای اهداف امنیتی و حسابرسی

---

### 1.2 نمودار روابط ERD

```
┌─────────────────┐       ┌─────────────────┐
│   job_groups    │       │  job_positions  │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │       │ id (PK)         │
│ name            │       │ name            │
│ description     │       │ description     │
│ is_active       │       │ is_active       │
└────────┬────────┘       └────────┬────────┘
         │                         │
         │ Many-to-One             │ Many-to-One
         ▼                         ▼
┌─────────────────────────────────────────────┐
│                   users                     │
├─────────────────────────────────────────────┤
│ id (PK)                                     │
│ personnel_code (UNIQUE)                     │
│ first_name, last_name                       │
│ email (UNIQUE)                              │
│ password_hash                               │
│ job_group_id (FK → job_groups)              │
│ job_position_id (FK → job_positions)        │
│ role (ENUM)                                 │
│ is_active                                   │
└──────────────────┬──────────────────────────┘
                   │
                   │ One-to-Many
                   ▼
┌─────────────────────────────────────────────┐
│              tsr_requests                   │
├─────────────────────────────────────────────┤
│ id (PK)                                     │
│ request_number (UNIQUE)                     │
│ title, description                          │
│ requester_id (FK → users)                   │
│ current_state_id (FK → workflow_states)     │
│ priority (ENUM)                             │
│ category, location                          │
│ assigned_to (FK → users)                    │
│ due_date, completed_at                      │
└──────────────────┬──────────────────────────┘
                   │
         ┌─────────┼─────────┐
         │         │         │
         ▼         ▼         ▼
┌─────────────┐ ┌──────┐ ┌──────────────┐
│   history   │ │files │ │ custom_fields│
└─────────────┘ └──────┘ └──────────────┘
```

---

## 2. معماری سیستم

### 2.1 نمای کلی جریان کار

```
┌─────────────────────────────────────────────────────────────────┐
│                        TSR System Architecture                  │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Requester  │────▶│  Supervisor  │────▶│    Manager   │
│   (کاربر)    │     │   (سرپرست)   │     │    (مدیر)    │
└──────────────┘     └──────────────┘     └──────────────┘
       │                    │                    │
       ▼                    ▼                    ▼
┌──────────────────────────────────────────────────────────────┐
│                    Application Layer                         │
│  ┌────────────┐  ┌────────────┐  ┌────────────────────┐     │
│  │   Auth     │  │    TSR     │  │     Workflow       │     │
│  │   Module   │  │   Module   │  │      Engine        │     │
│  └────────────┘  └────────────┘  └────────────────────┘     │
│  ┌────────────┐  ┌────────────┐  ┌────────────────────┐     │
│  │   Admin    │  │   Reports  │  │    Form Builder    │     │
│  │   Panel    │  │   Module   │  │      Dynamic       │     │
│  └────────────┘  └────────────┘  └────────────────────┘     │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                    Database Layer                            │
│  ┌────────────┐  ┌────────────┐  ┌────────────────────┐     │
│  │   Users    │  │   TSR      │  │     Workflow       │     │
│  │   Tables   │  │   Tables   │  │      Tables        │     │
│  └────────────┘  └────────────┘  └────────────────────┘     │
└──────────────────────────────────────────────────────────────┘
```

---

### 2.2 فلوچارت کامل جریان کار TSR

```
┌─────────────────────────────────────────────────────────────────┐
│                    TSR Workflow Diagram                         │
└─────────────────────────────────────────────────────────────────┘

    ┌─────────────┐
    │   START     │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐
    │  Login &    │
    │ Authenticate│
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐
    │  Dashboard  │◀────────────────────────┐
    └──────┬──────┘                         │
           │                                │
           ▼                                │
    ┌─────────────┐                         │
    │ Create New  │                         │
    │   TSR       │                         │
    └──────┬──────┘                         │
           │                                │
           ▼                                │
    ┌─────────────┐                         │
    │  Fill Form  │                         │
    │  (Dynamic)  │                         │
    └──────┬──────┘                         │
           │                                │
           ▼                                │
    ┌─────────────┐                         │
    │   Submit    │                         │
    │  Request    │                         │
    └──────┬──────┘                         │
           │                                │
           ▼                                │
    ┌─────────────┐                         │
    │   DRAFT     │─────────────────────────┘
    │   State     │  (User can edit)
    └──────┬──────┘
           │
           │ Submit
           ▼
    ┌─────────────┐
    │  SUBMITTED  │
    │   State     │
    └──────┬──────┘
           │
           │ Auto-assign to Supervisor
           ▼
    ┌─────────────┐
    │ UNDER_REVIEW│◀─────────────────────────┐
    │   State     │                          │
    └──────┬──────┘                          │
           │                                 │
     ┌─────┴─────┐                           │
     │           │                           │
     ▼           ▼                           │
┌─────────┐ ┌─────────┐                      │
│ APPROVED│ │ REJECTED│──────────────────────┘
│  State  │ │  State  │  (Return to draft)
└────┬────┘ └─────────┘
     │
     │ Assign to Manager
     ▼
┌─────────────┐
│ IN_PROGRESS │
│   State     │
└──────┬──────┘
       │
       │ Complete Work
       ▼
┌─────────────┐
│  COMPLETED  │
│   State     │
└──────┬──────┘
       │
       │ Quality Check (Optional)
       ▼
    ┌─────────────┐
    │     END     │
    └─────────────┘
```

---

### 2.3 تعاملات بین اجزا

#### **Authentication Flow:**
```
User Input → Security.sanitize() → Database.query() 
→ Security.verifyPassword() → Session.create() 
→ Security.regenerateSession() → Dashboard
```

#### **TSR Creation Flow:**
```
Form Display → FormFields.getActive() → User Input 
→ Security.validate() → Database.transaction() 
→ TSR.insert() → CustomFields.insert() 
→ History.log() → Notification.send()
```

#### **Workflow Transition Flow:**
```
Current State → Transitions.getAvailable() 
→ Permission.check() → User Action 
→ State.update() → History.log() 
→ Audit.record() → Notification.send()
```

#### **Excel Export Flow:**
```
Filter Criteria → Query.build() → Database.fetchAll() 
→ PHPExcel.generate() → Headers.set() 
→ File.download() → Audit.log()
```

---

## 3. ساختار فنی

### 3.1 ساختار پوشه‌ها و فایل‌ها

```
tsr_system/
│
├── config/                         # تنظیمات سیستم
│   ├── config.php                  # تنظیمات اصلی
│   ├── database.php                # تنظیمات پایگاه داده
│   └── routes.php                  # تعریف مسیرها
│
├── includes/                       # کتابخانه‌های اصلی
│   ├── Database.php                # کلاس اتصال به پایگاه داده
│   ├── Security.php                # توابع امنیتی
│   ├── Auth.php                    # مدیریت احراز هویت
│   ├── Validator.php               # اعتبارسنجی داده‌ها
│   ├── Logger.php                  # سیستم لاگ‌گیری
│   └── Helper.php                  # توابع کمکی
│
├── modules/                        # ماژول‌های سیستم
│   │
│   ├── auth/                       # ماژول احراز هویت
│   │   ├── login.php               # صفحه ورود
│   │   ├── logout.php              # خروج
│   │   ├── register.php            # ثبت‌نام (اختیاری)
│   │   └── forgot_password.php     # بازیابی رمز
│   │
│   ├── tsr/                        # ماژول مدیریت TSR
│   │   ├── list.php                # لیست درخواست‌ها
│   │   ├── create.php              # ایجاد درخواست جدید
│   │   ├── edit.php                # ویرایش درخواست
│   │   ├── view.php                # مشاهده جزئیات
│   │   └── delete.php              # حذف درخواست
│   │
│   ├── workflow/                   # ماژول جریان کار
│   │   ├── states.php              # مدیریت وضعیت‌ها
│   │   ├── transitions.php         # مدیریت انتقال‌ها
│   │   ├── approve.php             # تایید درخواست
│   │   └── reject.php              # رد درخواست
│   │
│   ├── admin/                      # پنل مدیریت
│   │   ├── dashboard.php           # داشبورد مدیریت
│   │   ├── users.php               # مدیریت کاربران
│   │   ├── roles.php               # مدیریت نقش‌ها
│   │   ├── fields.php              # مدیریت فیلدهای پویا
│   │   ├── settings.php            # تنظیمات سیستم
│   │   └── audit.php               # لاگ حسابرسی
│   │
│   └── reports/                    # ماژول گزارش‌گیری
│       ├── excel_export.php        # خروجی اکسل
│       ├── pdf_export.php          # خروجی PDF
│       ├── statistics.php          # آمار و نمودارها
│       └── history.php             # تاریخچه
│
├── templates/                      # قالب‌های HTML
│   ├── header.php                  # هدر مشترک
│   ├── footer.php                  # فوتر مشترک
│   ├── sidebar.php                 # منوی کناری
│   ├── navbar.php                  # نوار بالایی
│   └── components/                 # کامپوننت‌ها
│       ├── modal.php               # مودال‌ها
│       ├── table.php               # جدول‌ها
│       ├── form.php                # فرم‌ها
│       └── cards.php               # کارت‌ها
│
├── assets/                         # فایل‌های استاتیک
│   ├── css/                        # فایل‌های CSS
│   │   ├── style.css               # استایل اصلی
│   │   ├── rtl.css                 # استایل راست‌چین
│   │   └── responsive.css          # استایل واکنش‌گرا
│   ├── js/                         # فایل‌های JavaScript
│   │   ├── main.js                 # اسکریپت اصلی
│   │   ├── workflow.js             # منطق جریان کار
│   │   ├── forms.js                # مدیریت فرم‌ها
│   │   └── charts.js               # نمودارها
│   └── images/                     # تصاویر
│       ├── logo.png
│       └── icons/
│
├── uploads/                        # فایل‌های آپلود شده
│   ├── documents/                  # اسناد
│   ├── images/                     # تصاویر
│   └── temp/                       # فایل‌های موقت
│
├── logs/                           # فایل‌های لاگ
│   ├── error.log                   # لاگ خطاها
│   ├── access.log                  # لاگ دسترسی
│   └── audit.log                   # لاگ حسابرسی
│
├── database/                       # فایل‌های پایگاه داده
│   ├── schema.sql                  # ساختار پایگاه داده
│   ├── seed.sql                    # داده‌های اولیه
│   └── migrations/                 # مهاجرت‌ها
│
├── index.php                       # نقطه ورود اصلی
├── .htaccess                       # تنظیمات Apache
├── robots.txt                      # تنظیمات ربات‌ها
└── README.md                       # مستندات
```

---

### 3.2 بهترین روش‌های PHP

#### **سازماندهی کد:**

```php
// ✅ الگوی صحیح: استفاده از کلاس‌ها و متدها
class TSRManager {
    private $db;
    
    public function __construct($database) {
        $this->db = $database;
    }
    
    public function createRequest($data) {
        // Validation
        $validated = $this->validate($data);
        
        // Transaction
        $this->db->beginTransaction();
        try {
            // Insert request
            $requestId = $this->insertRequest($validated);
            
            // Insert custom fields
            $this->insertCustomFields($requestId, $data);
            
            // Log history
            $this->logHistory($requestId, 'create');
            
            $this->db->commit();
            return $requestId;
        } catch (Exception $e) {
            $this->db->rollback();
            throw $e;
        }
    }
}

// ❌ الگوی غلط: کد اسپاگتی
function create_request() {
    global $conn;
    $title = $_POST['title']; // No validation!
    mysqli_query($conn, "INSERT INTO..."); // No prepared statement!
}
```

#### **استفاده از Prepared Statements:**

```php
// ✅ صحیح - جلوگیری از SQL Injection
public function getUserById($id) {
    $sql = "SELECT * FROM users WHERE id = ? AND is_active = 1";
    return $this->db->fetchOne($sql, [$id]);
}

// ❌ غلط - آسیب‌پذیر به SQL Injection
public function getUserById($id) {
    return $this->db->query("SELECT * FROM users WHERE id = $id");
}
```

#### **مدیریت خطا:**

```php
// ✅ صحیح - Try-Catch با لاگ‌گیری
try {
    $this->db->beginTransaction();
    // Operations...
    $this->db->commit();
} catch (PDOException $e) {
    $this->db->rollback();
    error_log("Database error: " . $e->getMessage());
    Logger::error('DB_ERROR', ['message' => $e->getMessage()]);
    
    if (AppConfig::APP_ENV === 'production') {
        throw new Exception("عملیات با خطا مواجه شد");
    } else {
        throw $e;
    }
}
```

---

### 3.3 الگوهای طراحی استفاده‌شده

#### **Singleton Pattern (پایگاه داده):**
```php
class Database {
    private static $instance = null;
    private $connection;
    
    private function __construct() {
        // Initialize connection
    }
    
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
}
```

#### **Factory Pattern (ایجاد اشیاء):**
```php
class WorkflowFactory {
    public static function createState($type) {
        switch ($type) {
            case 'draft':
                return new DraftState();
            case 'submitted':
                return new SubmittedState();
            case 'approved':
                return new ApprovedState();
            default:
                throw new Exception("Invalid state type");
        }
    }
}
```

#### **Repository Pattern (دسترسی به داده):**
```php
interface UserRepositoryInterface {
    public function find($id);
    public function findAll();
    public function save($user);
    public function delete($id);
}

class UserRepository implements UserRepositoryInterface {
    private $db;
    
    public function __construct(Database $db) {
        $this->db = $db;
    }
    
    public function find($id) {
        return $this->db->fetchOne("SELECT * FROM users WHERE id = ?", [$id]);
    }
    
    // Other methods...
}
```

---

## 4. پانل مدیریتی

### 4.1 قابلیت‌های اصلی

#### **داشبورد مدیریت:**
```
┌─────────────────────────────────────────────────────────────┐
│                    Admin Dashboard                          │
├─────────────────────────────────────────────────────────────┤
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐   │
│  │  Total    │ │  Active   │ │ Pending   │ │ Completed │   │
│  │ Requests  │ │  Users    │ │  Approvals│ │  Today    │   │
│  │    1,234  │ │    56     │ │    12     │ │    8      │   │
│  └───────────┘ └───────────┘ └───────────┘ └───────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Workflow Visualization                 │   │
│  │                                                     │   │
│  │  ○ Draft → ○ Submitted → ○ Review → ○ Approved    │   │
│  │                                    ↓                │   │
│  │                              ○ Rejected             │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌───────────────────┐ ┌───────────────────┐               │
│  │ Recent Requests   │ │ System Alerts     │               │
│  │ - TSR-2024-001    │ │ - 3 pending       │               │
│  │ - TSR-2024-002    │ │ - 1 overdue       │               │
│  └───────────────────┘ └───────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

---

### 4.2 مدیریت فیلدهای پویا

#### **صفحه مدیریت فیلدها:**

```php
// modules/admin/fields.php

class FieldManager {
    /**
     * دریافت تمام فیلدهای فعال
     */
    public function getActiveFields() {
        $sql = "SELECT * FROM form_fields 
                WHERE is_active = 1 
                ORDER BY sort_order ASC";
        return $this->db->fetchAll($sql);
    }
    
    /**
     * افزودن فیلد جدید
     */
    public function addField($data) {
        $sql = "INSERT INTO form_fields 
                (field_name, field_label, field_type, is_required, 
                 sort_order, field_options, validation_rules, 
                 icon, section, visible_roles) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        return $this->db->query($sql, [
            $data['name'],
            $data['label'],
            $data['type'],
            $data['required'] ? 1 : 0,
            $data['sort_order'],
            json_encode($data['options']),
            json_encode($data['validation']),
            $data['icon'],
            $data['section'],
            json_encode($data['visible_roles'])
        ]);
    }
    
    /**
     * به‌روزرسانی فیلد
     */
    public function updateField($id, $data) {
        $sql = "UPDATE form_fields SET 
                field_label = ?, field_type = ?, is_required = ?,
                sort_order = ?, field_options = ?, validation_rules = ?,
                icon = ?, section = ?, visible_roles = ?,
                updated_at = NOW()
                WHERE id = ?";
        
        return $this->db->query($sql, [
            $data['label'],
            $data['type'],
            $data['required'] ? 1 : 0,
            $data['sort_order'],
            json_encode($data['options']),
            json_encode($data['validation']),
            $data['icon'],
            $data['section'],
            json_encode($data['visible_roles']),
            $id
        ]);
    }
    
    /**
     * حذف فیلد (Soft Delete)
     */
    public function deleteField($id) {
        $sql = "UPDATE form_fields SET is_active = 0 WHERE id = ?";
        return $this->db->query($sql, [$id]);
    }
    
    /**
     * تغییر ترتیب فیلدها
     */
    public function reorderFields($orderArray) {
        $this->db->beginTransaction();
        try {
            foreach ($orderArray as $index => $fieldId) {
                $sql = "UPDATE form_fields SET sort_order = ? WHERE id = ?";
                $this->db->query($sql, [$index, $fieldId]);
            }
            $this->db->commit();
        } catch (Exception $e) {
            $this->db->rollback();
            throw $e;
        }
    }
}
```

#### **رابط کاربری مدیریت فیلدها:**

```html
<!-- templates/components/field-builder.php -->
<div class="field-builder">
    <div class="toolbar">
        <button onclick="addField()">افزودن فیلد جدید</button>
        <button onclick="saveOrder()">ذخیره ترتیب</button>
    </div>
    
    <div class="fields-list" id="fieldsList">
        <!-- فیلدها به صورت پویا بارگذاری می‌شوند -->
    </div>
    
    <div class="field-modal" id="fieldModal">
        <form id="fieldForm">
            <input type="text" name="field_name" placeholder="نام فیلد">
            <input type="text" name="field_label" placeholder="برچسب">
            <select name="field_type">
                <option value="text">متن</option>
                <option value="textarea">متن طولانی</option>
                <option value="number">عدد</option>
                <option value="date">تاریخ</option>
                <option value="select">انتخابی</option>
                <option value="file">فایل</option>
            </select>
            <input type="text" name="icon" placeholder="آیکون (fa-*)">
            <input type="text" name="section" placeholder="بخش">
            <label>
                <input type="checkbox" name="is_required"> اجباری
            </label>
            <textarea name="field_options" placeholder="گزینه‌ها (JSON)"></textarea>
            <textarea name="validation_rules" placeholder="قوانین (JSON)"></textarea>
        </form>
    </div>
</div>
```

---

### 4.3 مدیریت وضعیت‌ها و انتقال‌ها

```php
// modules/workflow/states.php

class WorkflowManager {
    /**
     * دریافت وضعیت‌های جریان کار
     */
    public function getStates() {
        $sql = "SELECT * FROM workflow_states 
                WHERE is_active = 1 
                ORDER BY sort_order ASC";
        return $this->db->fetchAll($sql);
    }
    
    /**
     * افزودن وضعیت جدید
     */
    public function addState($data) {
        $sql = "INSERT INTO workflow_states 
                (name, code, description, color, icon, 
                 sort_order, is_initial, is_final) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        
        return $this->db->query($sql, [
            $data['name'],
            $data['code'],
            $data['description'],
            $data['color'],
            $data['icon'],
            $data['sort_order'],
            $data['is_initial'] ? 1 : 0,
            $data['is_final'] ? 1 : 0
        ]);
    }
    
    /**
     * دریافت انتقال‌های ممکن از یک وضعیت
     */
    public function getAvailableTransitions($stateId, $userRole) {
        $sql = "SELECT wt.*, ws.name as to_state_name, ws.color, ws.icon
                FROM workflow_transitions wt
                JOIN workflow_states ws ON wt.to_state_id = ws.id
                WHERE wt.from_state_id = ? 
                AND wt.is_active = 1
                AND (wt.required_role IS NULL OR wt.required_role <= ?)
                ORDER BY wt.id ASC";
        
        return $this->db->fetchAll($sql, [$stateId, $userRole]);
    }
    
    /**
     * انجام انتقال وضعیت
     */
    public function transition($requestId, $transitionId, $userId, $comments = null) {
        $this->db->beginTransaction();
        try {
            // دریافت اطلاعات انتقال
            $transition = $this->db->fetchOne(
                "SELECT * FROM workflow_transitions WHERE id = ?",
                [$transitionId]
            );
            
            // به‌روزرسانی وضعیت درخواست
            $sql = "UPDATE tsr_requests 
                    SET current_state_id = ?, updated_at = NOW()
                    WHERE id = ?";
            $this->db->query($sql, [$transition['to_state_id'], $requestId]);
            
            // ثبت در تاریخچه
            $this->logHistory($requestId, $transition, $userId, $comments);
            
            // به‌روزرسانی تاریخ تکمیل اگر وضعیت نهایی است
            $toState = $this->db->fetchOne(
                "SELECT is_final FROM workflow_states WHERE id = ?",
                [$transition['to_state_id']]
            );
            
            if ($toState['is_final']) {
                $this->db->query(
                    "UPDATE tsr_requests SET completed_at = NOW() WHERE id = ?",
                    [$requestId]
                );
            }
            
            $this->db->commit();
            return true;
        } catch (Exception $e) {
            $this->db->rollback();
            throw $e;
        }
    }
}
```

---

### 4.4 مدیریت کاربران و سطح دسترسی

```php
// modules/admin/users.php

class UserManager {
    /**
     * ایجاد کاربر جدید
     */
    public function createUser($data) {
        $sql = "INSERT INTO users 
                (personnel_code, first_name, last_name, email, 
                 password_hash, job_group_id, job_position_id, role) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        
        return $this->db->query($sql, [
            $data['personnel_code'],
            $data['first_name'],
            $data['last_name'],
            $data['email'],
            Security::hashPassword($data['password']),
            $data['job_group_id'],
            $data['job_position_id'],
            $data['role']
        ]);
    }
    
    /**
     * بررسی تکراری نبودن کد پرسنلی و ایمیل
     */
    public function isUnique($personnelCode, $email, $excludeId = null) {
        $sql = "SELECT COUNT(*) as count FROM users 
                WHERE (personnel_code = ? OR email = ?)";
        $params = [$personnelCode, $email];
        
        if ($excludeId) {
            $sql .= " AND id != ?";
            $params[] = $excludeId;
        }
        
        $result = $this->db->fetchOne($sql, $params);
        return $result['count'] == 0;
    }
    
    /**
     * قفل کردن کاربر پس از تلاش‌های ناموفق
     */
    public function handleFailedLogin($userId) {
        $sql = "UPDATE users 
                SET login_attempts = login_attempts + 1,
                    locked_until = CASE 
                        WHEN login_attempts >= 4 
                        THEN DATE_ADD(NOW(), INTERVAL 15 MINUTE)
                        ELSE locked_until
                    END
                WHERE id = ?";
        
        $this->db->query($sql, [$userId]);
    }
    
    /**
     * ریست کردن تلاش‌های ورود پس از ورود موفق
     */
    public function resetLoginAttempts($userId) {
        $sql = "UPDATE users 
                SET login_attempts = 0, 
                    locked_until = NULL,
                    last_login = NOW()
                WHERE id = ?";
        
        $this->db->query($sql, [$userId]);
    }
    
    /**
     * بررسی قفل بودن کاربر
     */
    public function isLocked($userId) {
        $user = $this->db->fetchOne(
            "SELECT locked_until FROM users WHERE id = ?",
            [$userId]
        );
        
        if (!$user || !$user['locked_until']) {
            return false;
        }
        
        return strtotime($user['locked_until']) > time();
    }
}
```

---

### 4.5 تغییرات بدون ریستارت

**مکانیزم کش پویا:**

```php
class CacheManager {
    private static $cache = [];
    
    /**
     * دریافت فیلدها از کش یا پایگاه داده
     */
    public static function getFormFields($forceRefresh = false) {
        $cacheKey = 'form_fields_active';
        
        if ($forceRefresh || !isset(self::$cache[$cacheKey])) {
            $db = Database::getInstance();
            $sql = "SELECT * FROM form_fields WHERE is_active = 1 ORDER BY sort_order";
            self::$cache[$cacheKey] = $db->fetchAll($sql);
        }
        
        return self::$cache[$cacheKey];
    }
    
    /**
     * پاک کردن کش خاص
     */
    public static function clearCache($key) {
        unset(self::$cache[$key]);
    }
    
    /**
     * پاک کردن تمام کش
     */
    public static function clearAll() {
        self::$cache = [];
    }
}

// هنگام به‌روزرسانی فیلدها
FieldManager::updateField($id, $data);
CacheManager::clearCache('form_fields_active');
// تغییرات بلافاصله اعمال می‌شود
```

---

## 5. جزئیات فنی اجرایی

### 5.1 مدیریت Session و Authentication

```php
// includes/Auth.php

class Auth {
    /**
     * شروع جلسه امن
     */
    public static function startSecureSession() {
        Security::initSecureSession();
    }
    
    /**
     * ورود کاربر
     */
    public static function login($email, $password, $remember = false) {
        $db = Database::getInstance();
        
        // یافتن کاربر
        $user = $db->fetchOne(
            "SELECT * FROM users WHERE email = ? AND is_active = 1",
            [$email]
        );
        
        if (!$user) {
            return ['success' => false, 'message' => 'کاربر یافت نشد'];
        }
        
        // بررسی قفل بودن
        if (Security::isLocked($user['id'])) {
            return ['success' => false, 'message' => 'حساب کاربری قفل است'];
        }
        
        // بررسی رمز عبور
        if (!Security::verifyPassword($password, $user['password_hash'])) {
            // ثبت تلاش ناموفق
            UserManager::handleFailedLogin($user['id']);
            return ['success' => false, 'message' => 'رمز عبور اشتباه است'];
        }
        
        // ریست کردن تلاش‌ها
        UserManager::resetLoginAttempts($user['id']);
        
        // ایجاد جلسه
        self::createSession($user);
        
        //再生成 ID جلسه برای امنیت
        Security::regenerateSession();
        
        return ['success' => true, 'user' => $user];
    }
    
    /**
     * ایجاد جلسه کاربر
     */
    private static function createSession($user) {
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['user_email'] = $user['email'];
        $_SESSION['user_role'] = $user['role'];
        $_SESSION['personnel_code'] = $user['personnel_code'];
        $_SESSION['full_name'] = $user['first_name'] . ' ' . $user['last_name'];
        $_SESSION['login_time'] = time();
        $_SESSION['csrf_token'] = Security::generateCSRFToken();
        
        // ذخیره در لاگ
        self::logLogin($user['id']);
    }
    
    /**
     * بررسی احراز هویت
     */
    public static function check() {
        if (!isset($_SESSION['user_id'])) {
            return false;
        }
        
        // بررسی انقضای جلسه
        if (time() - $_SESSION['login_time'] > SecurityConfig::SESSION_LIFETIME) {
            self::logout();
            return false;
        }
        
        return true;
    }
    
    /**
     * بررسی مجوز
     */
    public static function can($permissionCode) {
        if (!self::check()) {
            return false;
        }
        
        $db = Database::getInstance();
        $role = $_SESSION['user_role'];
        
        $sql = "SELECT COUNT(*) as count 
                FROM role_permissions rp
                JOIN permissions p ON rp.permission_id = p.id
                WHERE rp.role = ? AND p.code = ?";
        
        $result = $db->fetchOne($sql, [$role, $permissionCode]);
        return $result['count'] > 0;
    }
    
    /**
     * خروج
     */
    public static function logout() {
        Security::destroySession();
        session_unset();
        session_destroy();
    }
    
    /**
     * ثبت ورود در لاگ
     */
    private static function logLogin($userId) {
        $db = Database::getInstance();
        $sql = "INSERT INTO audit_log 
                (user_id, action, ip_address, user_agent) 
                VALUES (?, 'login', ?, ?)";
        
        $db->query($sql, [
            $userId,
            $_SERVER['REMOTE_ADDR'],
            $_SERVER['HTTP_USER_AGENT']
        ]);
    }
}
```

---

### 5.2 صادرات Excel

```php
// modules/reports/excel_export.php

use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;
use PhpOffice\PhpSpreadsheet\Style\Fill;

class ExcelExporter {
    /**
     * صادرات درخواست‌های TSR به اکسل
     */
    public function exportTSRRequests($filters = []) {
        $spreadsheet = new Spreadsheet();
        $sheet = $spreadsheet->getActiveSheet();
        
        // تنظیمات RTL برای فارسی
        $sheet->setRightToLeft(true);
        
        // عنوان ستون‌ها
        $headers = [
            'شماره درخواست',
            'عنوان',
            'درخواست‌دهنده',
            'گروه شغلی',
            'سمت شغلی',
            'اولویت',
            'وضعیت',
            'تاریخ ایجاد',
            'تاریخ تکمیل',
            'توضیحات'
        ];
        
        // استایل هدر
        $sheet->fromArray($headers, null, 'A1');
        $sheet->getStyle('A1:J1')->applyFromArray([
            'fill' => [
                'fillType' => Fill::FILL_SOLID,
                'startColor' => ['rgb' => '4462C1']
            ],
            'font' => [
                'bold' => true,
                'color' => ['rgb' => 'FFFFFF']
            ],
            'alignment' => [
                'horizontal' => Alignment::HORIZONTAL_CENTER,
                'vertical' => Alignment::VERTICAL_CENTER
            ]
        ]);
        
        // دریافت داده‌ها
        $requests = $this->getTSRData($filters);
        
        // پر کردن داده‌ها
        $row = 2;
        foreach ($requests as $request) {
            $sheet->fromArray([
                $request['request_number'],
                $request['title'],
                $request['requester_name'],
                $request['job_group'],
                $request['job_position'],
                $this->translatePriority($request['priority']),
                $request['state_name'],
                $this->toJalali($request['created_at']),
                $request['completed_at'] ? $this->toJalali($request['completed_at']) : '',
                $request['description']
            ], null, "A{$row}");
            
            // استایل ردیف
            $sheet->getStyle("A{$row}:J{$row}")->applyFromArray([
                'alignment' => [
                    'horizontal' => Alignment::HORIZONTAL_RIGHT
                ],
                'borders' => [
                    'bottom' => ['borderStyle' => Border::BORDER_THIN]
                ]
            ]);
            
            // رنگ‌بندی بر اساس اولویت
            $priorityColors = [
                'low' => 'C6EFCE',
                'medium' => 'FFEB9C',
                'high' => 'FFC7CE',
                'critical' => 'FF0000'
            ];
            
            if (isset($priorityColors[$request['priority']])) {
                $sheet->getStyle("A{$row}:J{$row}")->applyFromArray([
                    'fill' => [
                        'fillType' => Fill::FILL_SOLID,
                        'startColor' => ['rgb' => $priorityColors[$request['priority']]]
                    ]
                ]);
            }
            
            $row++;
        }
        
        // تنظیم عرض ستون‌ها
        foreach (range('A', 'J') as $col) {
            $sheet->getColumnDimension($col)->setAutoSize(true);
        }
        
        // ارسال فایل
        header('Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        header('Content-Disposition: attachment;filename="TSR_Export_' . date('Y-m-d') . '.xlsx"');
        header('Cache-Control: max-age=0');
        
        $writer = new Xlsx($spreadsheet);
        $writer->save('php://output');
        exit;
    }
    
    /**
     * دریافت داده‌های TSR
     */
    private function getTSRData($filters) {
        $db = Database::getInstance();
        
        $sql = "SELECT 
                    tr.*,
                    CONCAT(u.first_name, ' ', u.last_name) as requester_name,
                    jg.name as job_group,
                    jp.name as job_position,
                    ws.name as state_name
                FROM tsr_requests tr
                JOIN users u ON tr.requester_id = u.id
                LEFT JOIN job_groups jg ON u.job_group_id = jg.id
                LEFT JOIN job_positions jp ON u.job_position_id = jp.id
                JOIN workflow_states ws ON tr.current_state_id = ws.id
                WHERE 1=1";
        
        $params = [];
        
        if (!empty($filters['from_date'])) {
            $sql .= " AND tr.created_at >= ?";
            $params[] = $filters['from_date'];
        }
        
        if (!empty($filters['to_date'])) {
            $sql .= " AND tr.created_at <= ?";
            $params[] = $filters['to_date'];
        }
        
        if (!empty($filters['status'])) {
            $sql .= " AND tr.current_state_id = ?";
            $params[] = $filters['status'];
        }
        
        if (!empty($filters['priority'])) {
            $sql .= " AND tr.priority = ?";
            $params[] = $filters['priority'];
        }
        
        return $db->fetchAll($sql, $params);
    }
    
    /**
     * ترجمه اولویت
     */
    private function translatePriority($priority) {
        $translations = [
            'low' => 'کم',
            'medium' => 'متوسط',
            'high' => 'زیاد',
            'critical' => 'بحرانی'
        ];
        return $translations[$priority] ?? $priority;
    }
    
    /**
     * تبدیل تاریخ میلادی به شمسی
     */
    private function toJalali($date) {
        // استفاده از کتابخانه jdf یا مشابه
        return jdate('Y/m/d H:i', strtotime($date));
    }
}
```

---

### 5.3 الگوهای کدنویسی قوی

#### **الگوی Repository:**

```php
interface RepositoryInterface {
    public function find($id);
    public function findAll($filters = []);
    public function create($data);
    public function update($id, $data);
    public function delete($id);
}

class TSRRepository implements RepositoryInterface {
    private $db;
    
    public function __construct(Database $db) {
        $this->db = $db;
    }
    
    public function find($id) {
        $sql = "SELECT tr.*, 
                       CONCAT(u.first_name, ' ', u.last_name) as requester_name,
                       ws.name as state_name
                FROM tsr_requests tr
                JOIN users u ON tr.requester_id = u.id
                JOIN workflow_states ws ON tr.current_state_id = ws.id
                WHERE tr.id = ?";
        
        return $this->db->fetchOne($sql, [$id]);
    }
    
    public function findAll($filters = []) {
        // Implementation...
    }
    
    public function create($data) {
        // Implementation...
    }
    
    public function update($id, $data) {
        // Implementation...
    }
    
    public function delete($id) {
        // Implementation...
    }
}
```

#### **الگوی Service Layer:**

```php
class TSRService {
    private $repository;
    private $workflowManager;
    private $notificationService;
    
    public function __construct(
        TSRRepository $repository,
        WorkflowManager $workflowManager,
        NotificationService $notificationService
    ) {
        $this->repository = $repository;
        $this->workflowManager = $workflowManager;
        $this->notificationService = $notificationService;
    }
    
    public function submitRequest($data) {
        // Business logic
        $requestId = $this->repository->create($data);
        
        // Workflow transition
        $this->workflowManager->transition(
            $requestId,
            $this->getInitialTransitionId(),
            $_SESSION['user_id']
        );
        
        // Send notification
        $this->notificationService->notifySupervisors($requestId);
        
        return $requestId;
    }
}
```

---

## 6. امنیت

### 6.1 محافظت در برابر SQL Injection

```php
// ✅ استفاده از Prepared Statements
class SafeQuery {
    private $db;
    
    public function getUser($id) {
        // صحیح
        return $this->db->fetchOne(
            "SELECT * FROM users WHERE id = ?",
            [$id]
        );
    }
    
    public function searchRequests($keyword) {
        // صحیح - با LIKE
        return $this->db->fetchAll(
            "SELECT * FROM tsr_requests WHERE title LIKE ?",
            ["%{$keyword}%"]
        );
    }
    
    public function getRequestsByStatus($statuses) {
        // صحیح - با IN clause
        $placeholders = implode(',', array_fill(0, count($statuses), '?'));
        return $this->db->fetchAll(
            "SELECT * FROM tsr_requests WHERE current_state_id IN ($placeholders)",
            $statuses
        );
    }
}

// ❌ موارد ناامن
$unsafe = mysqli_query($conn, "SELECT * FROM users WHERE id = $_GET[id]");
```

---

### 6.2 محافظت در برابر XSS

```php
class XSSProtection {
    /**
     * خروجی ایمن برای HTML
     */
    public static function escape($data) {
        if (is_array($data)) {
            return array_map([self::class, 'escape'], $data);
        }
        return htmlspecialchars($data, ENT_QUOTES | ENT_HTML5, 'UTF-8');
    }
    
    /**
     * خروجی ایمن برای JavaScript
     */
    public static function escapeJS($data) {
        return json_encode($data, JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_QUOT | JSON_HEX_AMP);
    }
    
    /**
     * خروجی ایمن برای URL
     */
    public static function escapeURL($data) {
        return urlencode($data);
    }
    
    /**
     * تمیز کردن HTML (اجازه تگ‌های محدود)
     */
    public static function sanitizeHTML($data) {
        $allowed = '<p><br><strong><em><ul><ol><li><a>';
        return strip_tags($data, $allowed);
    }
}

// استفاده در template
echo XSSProtection::escape($user['first_name']);
```

---

### 6.3 محافظت در برابر CSRF

```php
// تولید توکن در فرم
<form method="POST" action="create.php">
    <input type="hidden" name="csrf_token" value="<?php echo Security::generateCSRFToken(); ?>">
    <!-- سایر فیلدها -->
</form>

// بررسی توکن در سرور
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!Security::verifyCSRFToken($_POST['csrf_token'] ?? '')) {
        http_response_code(403);
        die('CSRF token validation failed');
    }
    // ادامه پردازش
}
```

---

### 6.4 مدیریت Session امن

```php
class SecureSession {
    public static function init() {
        // تنظیمات امنیتی
        ini_set('session.cookie_httponly', '1');
        ini_set('session.cookie_secure', isset($_SERVER['HTTPS']) ? '1' : '0');
        ini_set('session.use_strict_mode', '1');
        ini_set('session.use_only_cookies', '1');
        
        // نام سفارشی برای جلسه
        ini_set('session.name', 'TSR_SECURE_SESSION');
        
        // زمان انقضا
        ini_set('session.gc_maxlifetime', SecurityConfig::SESSION_LIFETIME);
        
        session_start();
    }
    
    public static function regenerate() {
        // جلوگیری از Session Fixation
        session_regenerate_id(true);
    }
    
    public static function destroy() {
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
```

---

### 6.5 کنترل دسترسی مبتنی بر نقش (RBAC)

```php
class RBAC {
    /**
     * بررسی مجوز کاربر
     */
    public static function checkPermission($permissionCode) {
        if (!Auth::check()) {
            return false;
        }
        
        $db = Database::getInstance();
        $role = $_SESSION['user_role'];
        
        // کش کردن مجوزها
        $cacheKey = "permissions_{$role}";
        static $permissions = [];
        
        if (!isset($permissions[$cacheKey])) {
            $sql = "SELECT p.code 
                    FROM role_permissions rp
                    JOIN permissions p ON rp.permission_id = p.id
                    WHERE rp.role = ?";
            
            $result = $db->fetchAll($sql, [$role]);
            $permissions[$cacheKey] = array_column($result, 'code');
        }
        
        return in_array($permissionCode, $permissions[$cacheKey]);
    }
    
    /**
     * Middleware برای محافظت از صفحات
     */
    public static function requirePermission($permissionCode) {
        if (!self::checkPermission($permissionCode)) {
            http_response_code(403);
            include 'templates/errors/403.php';
            exit;
        }
    }
    
    /**
     * بررسی نقش کاربر
     */
    public static function requireRole($roles) {
        if (!Auth::check()) {
            redirect('login.php');
        }
        
        $userRole = $_SESSION['user_role'];
        $allowedRoles = is_array($roles) ? $roles : [$roles];
        
        if (!in_array($userRole, $allowedRoles)) {
            http_response_code(403);
            include 'templates/errors/403.php';
            exit;
        }
    }
}

// استفاده
RBAC::requirePermission('create_request');
RBAC::requireRole(['admin', 'manager']);
```

---

### 6.6 اعتبارسنجی ورودی‌ها

```php
class Validator {
    private $errors = [];
    
    /**
     * اعتبارسنجی درخواست TSR
     */
    public function validateTSRRequest($data) {
        // عنوان
        if (empty(trim($data['title']))) {
            $this->errors['title'] = 'عنوان الزامی است';
        } elseif (strlen($data['title']) > 255) {
            $this->errors['title'] = 'عنوان نمی‌تواند بیشتر از 255 کاراکتر باشد';
        }
        
        // شرح
        if (empty(trim($data['description']))) {
            $this->errors['description'] = 'شرح الزامی است';
        }
        
        // اولویت
        $validPriorities = ['low', 'medium', 'high', 'critical'];
        if (!in_array($data['priority'], $validPriorities)) {
            $this->errors['priority'] = 'اولویت نامعتبر است';
        }
        
        // تاریخ سررسید (در صورت وجود)
        if (!empty($data['due_date'])) {
            $date = DateTime::createFromFormat('Y-m-d', $data['due_date']);
            if (!$date || $date->format('Y-m-d') !== $data['due_date']) {
                $this->errors['due_date'] = 'تاریخ نامعتبر است';
            }
        }
        
        return empty($this->errors);
    }
    
    /**
     * اعتبارسنجی ایمیل
     */
    public function validateEmail($email) {
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $this->errors['email'] = 'ایمیل نامعتبر است';
            return false;
        }
        return true;
    }
    
    /**
     * اعتبارسنجی رمز عبور
     */
    public function validatePassword($password) {
        if (strlen($password) < AppConfig::PASSWORD_MIN_LENGTH) {
            $this->errors['password'] = 'رمز عبور باید حداقل ' . AppConfig::PASSWORD_MIN_LENGTH . ' کاراکتر باشد';
            return false;
        }
        
        if (!preg_match('/[A-Z]/', $password)) {
            $this->errors['password'] = 'رمز عبور باید شامل حروف بزرگ باشد';
            return false;
        }
        
        if (!preg_match('/[0-9]/', $password)) {
            $this->errors['password'] = 'رمز عبور باید شامل عدد باشد';
            return false;
        }
        
        return true;
    }
    
    public function getErrors() {
        return $this->errors;
    }
    
    public function hasErrors() {
        return !empty($this->errors);
    }
}
```

---

## 7. رابط کاربری

### 7.1 اصول طراحی UX/UI

#### **رنگ‌بندی:**

```css
/* assets/css/style.css */
:root {
    /* رنگ‌های اصلی */
    --primary-color: #4462C1;
    --primary-dark: #354a9e;
    --primary-light: #6b84d9;
    
    /* رنگ‌های وضعیت */
    --success-color: #28a745;
    --warning-color: #ffc107;
    --danger-color: #dc3545;
    --info-color: #17a2b8;
    
    /* رنگ‌های خنثی */
    --gray-100: #f8f9fa;
    --gray-200: #e9ecef;
    --gray-300: #dee2e6;
    --gray-600: #6c757d;
    --gray-800: #343a40;
    
    /* پس‌زمینه */
    --bg-color: #f5f6fa;
    --card-bg: #ffffff;
    
    /* متن */
    --text-primary: #2c3e50;
    --text-secondary: #6c757d;
    
    /* سایه‌ها */
    --shadow-sm: 0 2px 4px rgba(0,0,0,0.1);
    --shadow-md: 0 4px 8px rgba(0,0,0,0.12);
    --shadow-lg: 0 8px 16px rgba(0,0,0,0.15);
    
    /* گردی گوشه‌ها */
    --border-radius: 8px;
    --border-radius-lg: 12px;
}
```

---

#### **طراحی واکنش‌گرا:**

```css
/* assets/css/responsive.css */
.container {
    width: 100%;
    padding-right: 15px;
    padding-left: 15px;
    margin-right: auto;
    margin-left: auto;
}

@media (min-width: 576px) {
    .container { max-width: 540px; }
}

@media (min-width: 768px) {
    .container { max-width: 720px; }
}

@media (min-width: 992px) {
    .container { max-width: 960px; }
}

@media (min-width: 1200px) {
    .container { max-width: 1140px; }
}

/* منوی موبایل */
.sidebar {
    position: fixed;
    top: 0;
    right: -280px;
    width: 280px;
    height: 100vh;
    transition: right 0.3s ease;
    z-index: 1000;
}

.sidebar.active {
    right: 0;
}

@media (min-width: 992px) {
    .sidebar {
        right: 0;
        width: 260px;
    }
}
```

---

### 7.2 کامپوننت‌های UI

#### **کارت وضعیت:**

```html
<!-- templates/components/cards.php -->
<div class="status-card status-card--<?php echo $status; ?>">
    <div class="status-card__icon">
        <i class="fas <?php echo $icon; ?>"></i>
    </div>
    <div class="status-card__content">
        <h3 class="status-card__title"><?php echo $title; ?></h3>
        <p class="status-card__value"><?php echo $value; ?></p>
        <span class="status-card__change <?php echo $change > 0 ? 'positive' : 'negative'; ?>">
            <?php echo $change > 0 ? '+' : ''; ?><?php echo $change; ?>%
        </span>
    </div>
</div>

<style>
.status-card {
    background: var(--card-bg);
    border-radius: var(--border-radius-lg);
    padding: 24px;
    box-shadow: var(--shadow-md);
    display: flex;
    align-items: center;
    gap: 20px;
    transition: transform 0.2s, box-shadow 0.2s;
}

.status-card:hover {
    transform: translateY(-4px);
    box-shadow: var(--shadow-lg);
}

.status-card__icon {
    width: 60px;
    height: 60px;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 28px;
}

.status-card--success .status-card__icon {
    background: rgba(40, 167, 69, 0.1);
    color: var(--success-color);
}

.status-card__title {
    font-size: 14px;
    color: var(--text-secondary);
    margin: 0 0 8px 0;
}

.status-card__value {
    font-size: 28px;
    font-weight: bold;
    color: var(--text-primary);
    margin: 0;
}

.status-card__change {
    font-size: 12px;
    font-weight: 600;
}

.status-card__change.positive { color: var(--success-color); }
.status-card__change.negative { color: var(--danger-color); }
</style>
```

---

#### **جدول داده‌ها:**

```html
<!-- templates/components/table.php -->
<div class="data-table-container">
    <table class="data-table">
        <thead>
            <tr>
                <th>شماره درخواست</th>
                <th>عنوان</th>
                <th>درخواست‌دهنده</th>
                <th>اولویت</th>
                <th>وضعیت</th>
                <th>تاریخ ایجاد</th>
                <th>عملیات</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($requests as $request): ?>
            <tr>
                <td><?php echo Security::escape($request['request_number']); ?></td>
                <td><?php echo Security::escape($request['title']); ?></td>
                <td><?php echo Security::escape($request['requester_name']); ?></td>
                <td>
                    <span class="badge badge--<?php echo $request['priority']; ?>">
                        <?php echo $priorityLabels[$request['priority']]; ?>
                    </span>
                </td>
                <td>
                    <span class="status-badge" style="background: <?php echo $request['color']; ?>">
                        <?php echo Security::escape($request['state_name']); ?>
                    </span>
                </td>
                <td><?php echo jdate('Y/m/d', strtotime($request['created_at'])); ?></td>
                <td>
                    <div class="action-buttons">
                        <a href="view.php?id=<?php echo $request['id']; ?>" class="btn btn--sm btn--info">
                            <i class="fas fa-eye"></i>
                        </a>
                        <?php if (RBAC::checkPermission('edit_request')): ?>
                        <a href="edit.php?id=<?php echo $request['id']; ?>" class="btn btn--sm btn--warning">
                            <i class="fas fa-edit"></i>
                        </a>
                        <?php endif; ?>
                    </div>
                </td>
            </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</div>

<style>
.data-table-container {
    background: var(--card-bg);
    border-radius: var(--border-radius-lg);
    box-shadow: var(--shadow-md);
    overflow: hidden;
}

.data-table {
    width: 100%;
    border-collapse: collapse;
}

.data-table th,
.data-table td {
    padding: 16px;
    text-align: right;
    border-bottom: 1px solid var(--gray-200);
}

.data-table th {
    background: var(--gray-100);
    font-weight: 600;
    color: var(--text-primary);
    font-size: 14px;
}

.data-table tbody tr:hover {
    background: var(--gray-100);
}

.badge {
    display: inline-block;
    padding: 4px 12px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 600;
}

.badge--low { background: #d4edda; color: #155724; }
.badge--medium { background: #fff3cd; color: #856404; }
.badge--high { background: #f8d7da; color: #721c24; }
.badge--critical { background: #dc3545; color: #fff; }

.status-badge {
    display: inline-block;
    padding: 4px 12px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 600;
    color: #fff;
}

.action-buttons {
    display: flex;
    gap: 8px;
}

.btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 8px 16px;
    border: none;
    border-radius: var(--border-radius);
    cursor: pointer;
    transition: all 0.2s;
    text-decoration: none;
}

.btn--sm {
    padding: 6px 12px;
    font-size: 14px;
}

.btn--info { background: var(--info-color); color: #fff; }
.btn--warning { background: var(--warning-color); color: #000; }

.btn:hover {
    opacity: 0.9;
    transform: translateY(-2px);
}
</style>
```

---

#### **نمودار گردش کار:**

```html
<!-- modules/workflow/visualizer.php -->
<div class="workflow-visualizer">
    <div class="workflow-nodes">
        <?php foreach ($states as $state): ?>
        <div class="workflow-node node--<?php echo $state['code']; ?>" 
             data-state="<?php echo $state['id']; ?>">
            <div class="node-icon" style="background: <?php echo $state['color']; ?>">
                <i class="fas <?php echo $state['icon']; ?>"></i>
            </div>
            <div class="node-label"><?php echo Security::escape($state['name']); ?></div>
            <?php if ($state['is_initial']): ?>
            <span class="node-badge">شروع</span>
            <?php endif; ?>
            <?php if ($state['is_final']): ?>
            <span class="node-badge node-badge--final">پایان</span>
            <?php endif; ?>
        </div>
        <?php endforeach; ?>
    </div>
    
    <svg class="workflow-connectors" id="connectors">
        <!-- خطوط اتصال به صورت پویا رسم می‌شوند -->
    </svg>
</div>

<script>
// assets/js/workflow.js
class WorkflowVisualizer {
    constructor() {
        this.nodes = document.querySelectorAll('.workflow-node');
        this.svg = document.getElementById('connectors');
        this.init();
    }
    
    init() {
        this.drawConnectors();
        this.setupNodeClicks();
    }
    
    drawConnectors() {
        // دریافت انتقال‌ها از API
        fetch('api/workflow/transitions.php')
            .then(response => response.json())
            .then(transitions => {
                transitions.forEach(transition => {
                    this.drawConnector(transition);
                });
            });
    }
    
    drawConnector(transition) {
        const fromNode = document.querySelector(`[data-state="${transition.from_state_id}"]`);
        const toNode = document.querySelector(`[data-state="${transition.to_state_id}"]`);
        
        const fromRect = fromNode.getBoundingClientRect();
        const toRect = toNode.getBoundingClientRect();
        
        const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        path.setAttribute('d', this.calculatePath(fromRect, toRect));
        path.setAttribute('stroke', '#4462C1');
        path.setAttribute('stroke-width', '2');
        path.setAttribute('fill', 'none');
        path.setAttribute('marker-end', 'url(#arrowhead)');
        
        this.svg.appendChild(path);
    }
    
    calculatePath(from, to) {
        const startX = from.left + from.width / 2;
        const startY = from.top + from.height / 2;
        const endX = to.left + to.width / 2;
        const endY = to.top + to.height / 2;
        
        // مسیر منحنی
        const controlX = (startX + endX) / 2;
        return `M ${startX} ${startY} Q ${controlX} ${startY} ${controlX} ${(startY + endY) / 2} T ${endX} ${endY}`;
    }
}

document.addEventListener('DOMContentLoaded', () => {
    new WorkflowVisualizer();
});
</script>

<style>
.workflow-visualizer {
    position: relative;
    padding: 40px;
    background: var(--card-bg);
    border-radius: var(--border-radius-lg);
    box-shadow: var(--shadow-md);
}

.workflow-nodes {
    display: flex;
    justify-content: space-around;
    flex-wrap: wrap;
    gap: 20px;
}

.workflow-node {
    position: relative;
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 20px;
    cursor: pointer;
    transition: transform 0.2s;
}

.workflow-node:hover {
    transform: scale(1.05);
}

.node-icon {
    width: 60px;
    height: 60px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #fff;
    font-size: 24px;
    margin-bottom: 10px;
}

.node-label {
    font-weight: 600;
    color: var(--text-primary);
}

.node-badge {
    position: absolute;
    top: -10px;
    right: -10px;
    background: var(--primary-color);
    color: #fff;
    padding: 2px 8px;
    border-radius: 10px;
    font-size: 10px;
}

.node-badge--final {
    background: var(--success-color);
}

.workflow-connectors {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    pointer-events: none;
    z-index: 0;
}
</style>
```

---

## 8. تست و مستندات

### 8.1 انواع تست‌های مورد نیاز

#### **تست واحد (Unit Tests):**

```php
// tests/Unit/ValidatorTest.php
use PHPUnit\Framework\TestCase;

class ValidatorTest extends TestCase {
    private $validator;
    
    protected function setUp(): void {
        $this->validator = new Validator();
    }
    
    public function testValidTSRRequest() {
        $data = [
            'title' => 'درخواست تعمیر',
            'description' => 'توضیحات کامل',
            'priority' => 'high',
            'due_date' => '2024-12-31'
        ];
        
        $this->assertTrue($this->validator->validateTSRRequest($data));
        $this->assertFalse($this->validator->hasErrors());
    }
    
    public function testMissingTitle() {
        $data = [
            'title' => '',
            'description' => 'توضیحات',
            'priority' => 'high'
        ];
        
        $this->assertFalse($this->validator->validateTSRRequest($data));
        $this->assertArrayHasKey('title', $this->validator->getErrors());
    }
    
    public function testInvalidPriority() {
        $data = [
            'title' => 'عنوان',
            'description' => 'توضیحات',
            'priority' => 'invalid'
        ];
        
        $this->assertFalse($this->validator->validateTSRRequest($data));
        $this->assertArrayHasKey('priority', $this->validator->getErrors());
    }
}
```

---

#### **تست یکپارچگی (Integration Tests):**

```php
// tests/Integration/TSRWorkflowTest.php
use PHPUnit\Framework\TestCase;

class TSRWorkflowTest extends TestCase {
    private $db;
    private $tsrService;
    
    protected function setUp(): void {
        $this->db = Database::getInstance();
        $this->tsrService = new TSRService(
            new TSRRepository($this->db),
            new WorkflowManager($this->db),
            new NotificationService()
        );
        
        // شروع تراکنش
        $this->db->beginTransaction();
    }
    
    protected function tearDown(): void {
        // بازگشت تراکنش
        $this->db->rollback();
    }
    
    public function testCreateAndSubmitRequest() {
        $requestData = [
            'title' => 'درخواست تست',
            'description' => 'توضیحات تست',
            'priority' => 'medium',
            'requester_id' => 1
        ];
        
        $requestId = $this->tsrService->submitRequest($requestData);
        
        $this->assertIsInt($requestId);
        
        $request = $this->db->fetchOne(
            "SELECT * FROM tsr_requests WHERE id = ?",
            [$requestId]
        );
        
        $this->assertEquals('درخواست تست', $request['title']);
        $this->assertEquals('submitted', $request['current_state_id']);
    }
    
    public function testWorkflowTransition() {
        // ایجاد درخواست
        $requestId = $this->createTestRequest();
        
        // انجام انتقال
        $result = $this->tsrService->transition(
            $requestId,
            2, // transition_id
            1, // user_id
            'توضیحات انتقال'
        );
        
        $this->assertTrue($result);
        
        // بررسی وضعیت جدید
        $request = $this->db->fetchOne(
            "SELECT current_state_id FROM tsr_requests WHERE id = ?",
            [$requestId]
        );
        
        $this->assertEquals(3, $request['current_state_id']); // under_review
    }
    
    private function createTestRequest() {
        $sql = "INSERT INTO tsr_requests 
                (request_number, title, description, requester_id, current_state_id, priority) 
                VALUES (?, ?, ?, ?, ?, ?)";
        
        $this->db->query($sql, [
            'TEST-' . time(),
            'درخواست تست',
            'توضیحات',
            1,
            1, // draft
            'medium'
        ]);
        
        return $this->db->lastInsertId();
    }
}
```

---

#### **تست امنیت (Security Tests):**

```php
// tests/Security/SQLInjectionTest.php
use PHPUnit\Framework\TestCase;

class SQLInjectionTest extends TestCase {
    public function testPreventSQLInjectionInLogin() {
        $auth = new Auth();
        
        // تلاش برای SQL Injection
        $result = $auth->login(
            "admin' OR '1'='1",
            "anything' OR '1'='1"
        );
        
        $this->assertFalse($result['success']);
    }
    
    public function testPreventSQLInjectionInSearch() {
        $repository = new TSRRepository(Database::getInstance());
        
        // تلاش برای SQL Injection
        $results = $repository->searchRequests(
            "' UNION SELECT * FROM users --"
        );
        
        // نباید اطلاعات کاربران را برگرداند
        foreach ($results as $result) {
            $this->assertArrayNotHasKey('password_hash', $result);
        }
    }
}

// tests/Security/XSSProtectionTest.php
class XSSProtectionTest extends TestCase {
    public function testEscapeScriptTags() {
        $malicious = '<script>alert("XSS")</script>';
        $safe = Security::escape($malicious);
        
        $this->assertStringNotContainsString('<script>', $safe);
        $this->assertEquals('&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;', $safe);
    }
    
    public function testEscapeEventHandlers() {
        $malicious = '<img src=x onerror="alert(1)">';
        $safe = Security::escape($malicious);
        
        $this->assertStringNotContainsString('onerror', $safe);
    }
}
```

---

### 8.2 اجرای تست‌ها

```bash
# نصب PHPUnit
composer require --dev phpunit/phpunit

# اجرای تست‌ها
./vendor/bin/phpunit tests/

# اجرای تست‌ها با گزارش پوشش کد
./vendor/bin/phpunit --coverage-html coverage/ tests/

# اجرای تست‌های خاص
./vendor/bin/phpunit tests/Unit/ValidatorTest.php
```

---

### 8.3 مستندات استقرار

#### **الزامات سرور:**

```yaml
# Production Requirements
Server:
  OS: Linux (Ubuntu 20.04+ or CentOS 8+)
  Web Server: Apache 2.4+ or Nginx 1.18+
  PHP: 8.0+
  Database: MySQL 8.0+ or MariaDB 10.5+
  
PHP Extensions:
  - pdo_mysql
  - mbstring
  - xml
  - zip
  - gd
  - intl
  
PHP Settings:
  memory_limit: 256M
  upload_max_filesize: 10M
  post_max_size: 10M
  max_execution_time: 60
  session.gc_maxlifetime: 3600
```

---

#### **مراحل استقرار:**

```bash
# 1. آپلود فایل‌ها
scp -r tsr_system/* user@server:/var/www/html/tsr/

# 2. تنظیم مجوزها
chmod -R 755 /var/www/html/tsr/
chmod -R 777 /var/www/html/tsr/uploads/
chmod -R 777 /var/www/html/tsr/logs/

# 3. ایجاد پایگاه داده
mysql -u root -p < database/schema.sql

# 4. تنظیمات محیط تولید
# ویرایش config/config.php
# تغییر APP_ENV به 'production'
# تنظیم DB_PASS
# تنظیم SESSION_SECURE به true (اگر HTTPS دارید)

# 5. تنظیم Apache
# ایجاد فایل VirtualHost
<VirtualHost *:80>
    ServerName tsr.yourcompany.com
    DocumentRoot /var/www/html/tsr
    
    <Directory /var/www/html/tsr>
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/tsr_error.log
    CustomLog ${APACHE_LOG_DIR}/tsr_access.log combined
</VirtualHost>

# 6. فعال‌سازی SSL (اختیاری اما توصیه می‌شود)
certbot --apache -d tsr.yourcompany.com

# 7. راه‌اندازی Cron Job برای کارهای پس‌زمینه
crontab -e
# افزودن:
0 * * * * php /var/www/html/tsr/cron/process_notifications.php
0 2 * * * php /var/www/html/tsr/cron/cleanup_temp.php
```

---

#### **پیکربندی Nginx:**

```nginx
server {
    listen 80;
    server_name tsr.yourcompany.com;
    root /var/www/html/tsr;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.0-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        
        # امنیت اضافی
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.ht {
        deny all;
    }

    location ~ /\.(git|env|sql)$ {
        deny all;
    }

    # کش‌گذاری فایل‌های استاتیک
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

---

### 8.4 مستندات نگهداری

#### **لاگ‌گیری و مانیتورینگ:**

```php
// includes/Logger.php
class Logger {
    const LEVEL_INFO = 'INFO';
    const LEVEL_WARNING = 'WARNING';
    const LEVEL_ERROR = 'ERROR';
    const LEVEL_CRITICAL = 'CRITICAL';
    
    public static function log($level, $message, $context = []) {
        $timestamp = date('Y-m-d H:i:s');
        $logMessage = sprintf(
            "[%s] [%s] %s %s\n",
            $timestamp,
            $level,
            $message,
            !empty($context) ? json_encode($context) : ''
        );
        
        $logFile = __DIR__ . '/../logs/' . strtolower($level) . '.log';
        file_put_contents($logFile, $logMessage, FILE_APPEND);
        
        // ارسال ایمیل برای خطاهای بحرانی
        if ($level === self::LEVEL_CRITICAL) {
            self::sendAlert($message, $context);
        }
    }
    
    public static function info($message, $context = []) {
        self::log(self::LEVEL_INFO, $message, $context);
    }
    
    public static function error($message, $context = []) {
        self::log(self::LEVEL_ERROR, $message, $context);
    }
    
    private static function sendAlert($message, $context) {
        // ارسال ایمیل به مدیران
        mail(
            'admin@company.com',
            'Critical Error in TSR System',
            $message . "\n" . json_encode($context)
        );
    }
}
```

---

#### **پشتیبان‌گیری خودکار:**

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backups/tsr"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="tsr_system"
DB_USER="root"
DB_PASS="your_password"

# ایجاد دایرکتوری
mkdir -p $BACKUP_DIR

# پشتیبان پایگاه داده
mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > $BACKUP_DIR/db_$DATE.sql

# فشرده‌سازی
tar -czf $BACKUP_DIR/files_$DATE.tar.gz /var/www/html/tsr/uploads/

# حذف پشتیبان‌های قدیمی (بیشتر از 30 روز)
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

# آپلود به فضای ابری (اختیاری)
# aws s3 cp $BACKUP_DIR s3://your-bucket/tsr-backups/

echo "Backup completed: $DATE"
```

---

#### **چک‌لیست نگهداری ماهانه:**

```markdown
## چک‌لیست نگهداری ماهانه

### امنیت
- [ ] بررسی لاگ‌های امنیتی
- [ ] به‌روزرسانی PHP و کتابخانه‌ها
- [ ] بررسی کاربران غیرفعال
- [ ] بررسی تلاش‌های ورود ناموفق

### عملکرد
- [ ] بررسی سرعت پاسخگویی
- [ ] بهینه‌سازی پایگاه داده (OPTIMIZE TABLE)
- [ ] پاک‌سازی کش
- [ ] بررسی فضای دیسک

### داده‌ها
- [ ] بررسی صحت پشتیبان‌ها
- [ ] تست بازیابی از پشتیبان
- [ ] آرشیو درخواست‌های قدیمی

### گزارش‌گیری
- [ ] تولید گزارش ماهانه
- [ ] بررسی آمار استفاده
- [ ] شناسایی گلوگاه‌ها
```

---

## خلاصه و نتیجه‌گیری

این مستندات یک سیستم TSR کامل و حرفه‌ای را توصیف می‌کند که شامل:

✅ **معماری پایگاه داده بهینه** با ۱۲ جدول اصلی و روابط صحیح
✅ **جریان کار پویا** با قابلیت مدیریت وضعیت‌ها و انتقال‌ها
✅ **فرم‌ساز پویا** برای مدیریت فیلدها بدون تغییر کد
✅ **امنیت چندلایه** شامل محافظت در برابر SQL Injection، XSS، CSRF
✅ **RBAC کامل** با ۴ نقش و ۱۰ مجوز مختلف
✅ **خروجی اکسل حرفه‌ای** با استایل‌بندی و رنگ‌بندی
✅ **رابط کاربری مدرن** با طراحی واکنش‌گرا و RTL
✅ **تست جامع** شامل Unit Test، Integration Test، Security Test
✅ **مستندات کامل** برای استقرار، نگهداری و توسعه

سیستم آماده استقرار در محیط تولید با XAMPP یا هر سرور Linux است.
