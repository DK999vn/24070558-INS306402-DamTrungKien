-- =====================================================================
-- Assignment : Homework 4 - University Course Registration Database
-- Course     : INS3064
-- Student    : <HỌ VÀ TÊN CỦA BẠN>
-- Student ID : <MÃ SỐ SINH VIÊN>
-- Date       : 2026-10-11
-- Description: Creates the university_db database (6 tables), all
--              constraints, and inserts realistic sample data.
--              The script is idempotent: it can be re-run safely.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Create the database from scratch (idempotent)
-- ---------------------------------------------------------------------
DROP DATABASE IF EXISTS university_db;
CREATE DATABASE university_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;   -- utf8mb4 so Vietnamese names display correctly
USE university_db;

-- Drop tables in reverse dependency order (child tables first)
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS instructors;
DROP TABLE IF EXISTS semesters;
DROP TABLE IF EXISTS departments;

-- ---------------------------------------------------------------------
-- 1. departments : academic departments (no foreign keys)
-- ---------------------------------------------------------------------
CREATE TABLE departments (
    id          INT           NOT NULL AUTO_INCREMENT,           -- surrogate PK
    code        VARCHAR(10)   NOT NULL,                          -- short code, e.g. CS
    name        VARCHAR(100)  NOT NULL,                          -- full department name
    description TEXT          NULL,                              -- optional long description
    created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,-- audit timestamp
    PRIMARY KEY (id),
    UNIQUE KEY uq_departments_code (code),                       -- no duplicate codes
    UNIQUE KEY uq_departments_name (name)                        -- no duplicate names
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. semesters : academic terms (no foreign keys)
-- ---------------------------------------------------------------------
CREATE TABLE semesters (
    id          INT           NOT NULL AUTO_INCREMENT,
    name        VARCHAR(30)   NOT NULL,                          -- e.g. 'Fall 2024'
    start_date  DATE          NOT NULL,
    end_date    DATE          NOT NULL,
    created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_semesters_name (name),
    CONSTRAINT chk_semesters_dates CHECK (end_date > start_date) -- end must be after start
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. instructors : teaching staff, each belongs to one department (1:N)
-- ---------------------------------------------------------------------
CREATE TABLE instructors (
    id              INT           NOT NULL AUTO_INCREMENT,
    department_id   INT           NOT NULL,                      -- FK -> departments.id
    instructor_code VARCHAR(20)   NOT NULL,                      -- staff code
    full_name       VARCHAR(100)  NOT NULL,
    email           VARCHAR(100)  NOT NULL,
    phone           VARCHAR(20)   NULL,
    hire_date       DATE          NOT NULL,
    created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_instructors_code  (instructor_code),
    UNIQUE KEY uq_instructors_email (email),
    -- RESTRICT: cannot delete a department that still has instructors
    -- CASCADE : if department id changes, update it here automatically
    CONSTRAINT fk_instructors_department
        FOREIGN KEY (department_id) REFERENCES departments (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. students : each student has one major (department) (1:N)
-- ---------------------------------------------------------------------
CREATE TABLE students (
    id            INT            NOT NULL AUTO_INCREMENT,
    department_id INT            NOT NULL,                       -- FK -> departments.id (major)
    student_code  VARCHAR(20)    NOT NULL,                       -- student ID card number
    full_name     VARCHAR(100)   NOT NULL,
    email         VARCHAR(100)   NOT NULL,
    gender        ENUM('male','female','other') NOT NULL DEFAULT 'other', -- fixed set of values
    date_of_birth DATE           NOT NULL,
    gpa           DECIMAL(3,2)   NOT NULL DEFAULT 0.00,          -- 0.00 - 4.00 (e.g. 3.45)
    status        ENUM('active','on_leave','graduated') NOT NULL DEFAULT 'active',
    enrolled_date DATE           NOT NULL DEFAULT (CURRENT_DATE),
    created_at    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_students_code  (student_code),
    UNIQUE KEY uq_students_email (email),
    CONSTRAINT chk_students_gpa CHECK (gpa BETWEEN 0.00 AND 4.00),
    CONSTRAINT fk_students_department
        FOREIGN KEY (department_id) REFERENCES departments (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. courses : each course is owned by a department and taught by an
--    instructor (two 1:N relationships)
-- ---------------------------------------------------------------------
CREATE TABLE courses (
    id            INT           NOT NULL AUTO_INCREMENT,
    department_id INT           NOT NULL,                        -- FK -> departments.id
    instructor_id INT           NOT NULL,                        -- FK -> instructors.id
    course_code   VARCHAR(20)   NOT NULL,                        -- e.g. CS101
    title         VARCHAR(150)  NOT NULL,
    description   TEXT          NULL,
    credits       TINYINT       NOT NULL DEFAULT 3,              -- number of credits
    created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_courses_code (course_code),
    CONSTRAINT chk_courses_credits CHECK (credits BETWEEN 1 AND 6),
    CONSTRAINT fk_courses_department
        FOREIGN KEY (department_id) REFERENCES departments (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_courses_instructor
        FOREIGN KEY (instructor_id) REFERENCES instructors (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. enrollments : junction table for the M:N relationship between
--    students and courses, per semester. Grade is optional (NULL while
--    the course is still in progress).
-- ---------------------------------------------------------------------
CREATE TABLE enrollments (
    id           INT           NOT NULL AUTO_INCREMENT,
    student_id   INT           NOT NULL,                         -- FK -> students.id
    course_id    INT           NOT NULL,                         -- FK -> courses.id
    semester_id  INT           NOT NULL,                         -- FK -> semesters.id
    grade        DECIMAL(3,2)  NULL,                             -- numeric grade, 4.0 scale
    grade_letter ENUM('A','B','C','D','F') NULL,                 -- letter grade
    enrolled_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    -- A student cannot register for the same course twice in one semester
    UNIQUE KEY unique_enrollment (student_id, course_id, semester_id),
    CONSTRAINT chk_enrollments_grade CHECK (grade IS NULL OR grade BETWEEN 0.00 AND 4.00),
    -- CASCADE: deleting a student also removes their enrollments
    CONSTRAINT fk_enrollments_student
        FOREIGN KEY (student_id) REFERENCES students (id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    -- RESTRICT: keep history, do not delete courses/semesters that have enrollments
    CONSTRAINT fk_enrollments_course
        FOREIGN KEY (course_id) REFERENCES courses (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_enrollments_semester
        FOREIGN KEY (semester_id) REFERENCES semesters (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================================================================
-- SAMPLE DATA (inserted in dependency order)
-- =====================================================================

-- departments (5 rows)
INSERT INTO departments (code, name, description) VALUES
('CS',   'Khoa học máy tính',       'Đào tạo về thuật toán, lập trình, trí tuệ nhân tạo và khoa học dữ liệu.'),
('IS',   'Hệ thống thông tin',      'Đào tạo về cơ sở dữ liệu, phân tích thiết kế và quản trị hệ thống thông tin.'),
('SE',   'Kỹ thuật phần mềm',       'Đào tạo quy trình phát triển, kiểm thử và bảo trì phần mềm.'),
('MATH', 'Toán học',                'Cung cấp nền tảng toán học và thống kê cho các ngành kỹ thuật.'),
('BA',   'Quản trị kinh doanh',     'Đào tạo về quản trị, marketing, tài chính và khởi nghiệp.');

-- semesters (5 rows)
INSERT INTO semesters (name, start_date, end_date) VALUES
('Fall 2023',   '2023-09-05', '2024-01-14'),
('Spring 2024', '2024-02-05', '2024-06-16'),
('Fall 2024',   '2024-09-05', '2025-01-12'),
('Spring 2025', '2025-02-03', '2025-06-15'),
('Fall 2025',   '2025-09-08', '2026-01-11');

-- instructors (6 rows)
INSERT INTO instructors (department_id, instructor_code, full_name, email, phone, hire_date) VALUES
(1, 'GV001', 'Nguyễn Văn Hùng',  'hung.nguyen@university.edu.vn', '0912345001', '2012-08-15'),
(2, 'GV002', 'Trần Thị Mai',     'mai.tran@university.edu.vn',    '0912345002', '2014-03-01'),
(3, 'GV003', 'Lê Quang Minh',    'minh.le@university.edu.vn',     '0912345003', '2016-09-10'),
(4, 'GV004', 'Phạm Thu Hà',      'ha.pham@university.edu.vn',     '0912345004', '2010-01-20'),
(1, 'GV005', 'Hoàng Đức Anh',    'anh.hoang@university.edu.vn',   '0912345005', '2018-07-05'),
(5, 'GV006', 'Vũ Thị Lan',       'lan.vu@university.edu.vn',      NULL,         '2015-11-12');

-- students (8 rows)
INSERT INTO students (department_id, student_code, full_name, email, gender, date_of_birth, gpa, status, enrolled_date) VALUES
(1, 'SV2023001', 'Nguyễn Minh Đức',      'duc.nm@student.edu.vn',    'male',   '2005-02-14', 3.45, 'active', '2023-09-05'),
(2, 'SV2023002', 'Trần Thị Ngọc Anh',    'anh.ttn@student.edu.vn',   'female', '2005-06-21', 3.20, 'active', '2023-09-05'),
(3, 'SV2023003', 'Lê Hoàng Nam',         'nam.lh@student.edu.vn',    'male',   '2005-09-30', 2.95, 'active', '2023-09-05'),
(4, 'SV2023004', 'Phạm Thị Thu Trang',   'trang.ptt@student.edu.vn', 'female', '2004-12-03', 3.60, 'active', '2023-09-05'),
(1, 'SV2024005', 'Đặng Quốc Bảo',        'bao.dq@student.edu.vn',    'male',   '2006-01-17', 2.60, 'active', '2024-09-05'),
(5, 'SV2024006', 'Vũ Khánh Linh',        'linh.vk@student.edu.vn',   'female', '2006-04-25', 3.80, 'active', '2024-09-05'),
(3, 'SV2024007', 'Bùi Thanh Tùng',       'tung.bt@student.edu.vn',   'male',   '2006-08-09', 3.10, 'on_leave','2024-09-05'),
(2, 'SV2024008', 'Ngô Thị Hải Yến',      'yen.nth@student.edu.vn',   'female', '2006-11-11', 2.75, 'active', '2024-09-05');

-- courses (8 rows)
INSERT INTO courses (department_id, instructor_id, course_code, title, description, credits) VALUES
(1, 1, 'CS101',   'Nhập môn lập trình',               'Làm quen với tư duy lập trình, biến, vòng lặp, hàm bằng Python.', 3),
(1, 5, 'CS201',   'Cấu trúc dữ liệu và giải thuật',   'Mảng, danh sách liên kết, cây, đồ thị và các thuật toán sắp xếp, tìm kiếm.', 4),
(2, 2, 'IS201',   'Cơ sở dữ liệu',                    'Mô hình quan hệ, SQL, chuẩn hóa và thiết kế cơ sở dữ liệu.', 3),
(2, 2, 'IS301',   'Phân tích thiết kế hệ thống',      'Phân tích yêu cầu, mô hình hóa UML và thiết kế hệ thống thông tin.', 3),
(3, 3, 'SE301',   'Công nghệ phần mềm',               'Vòng đời phần mềm, Agile/Scrum, kiểm thử và quản lý cấu hình.', 3),
(4, 4, 'MATH101', 'Giải tích 1',                      'Giới hạn, đạo hàm, tích phân của hàm một biến.', 4),
(4, 4, 'MATH201', 'Xác suất thống kê',                'Biến ngẫu nhiên, phân phối xác suất, ước lượng và kiểm định giả thuyết.', 3),
(5, 6, 'BA101',   'Nguyên lý quản trị',               'Các chức năng cơ bản của quản trị: hoạch định, tổ chức, lãnh đạo, kiểm soát.', 3);

-- enrollments (17 rows) - grade NULL means the course is still in progress
-- Grade letter scale: A >= 3.5 | B >= 2.5 | C >= 1.5 | D >= 1.0 | F < 1.0
INSERT INTO enrollments (student_id, course_id, semester_id, grade, grade_letter) VALUES
(1, 1, 1, 3.70, 'A'),
(1, 2, 2, 3.30, 'B'),
(1, 3, 3, 3.90, 'A'),
(2, 6, 1, 2.50, 'B'),
(2, 3, 3, 3.50, 'A'),
(2, 4, 4, 3.00, 'B'),
(3, 1, 1, 2.80, 'B'),
(3, 5, 3, 3.20, 'B'),
(4, 6, 1, 3.60, 'A'),
(4, 7, 2, 3.40, 'B'),
(5, 1, 2, 2.20, 'C'),
(5, 2, 3, 3.10, 'B'),
(6, 8, 3, 3.80, 'A'),
(7, 5, 4, NULL, NULL),
(7, 3, 5, NULL, NULL),
(8, 3, 4, 2.00, 'C'),
(8, 4, 5, NULL, NULL);

-- =====================================================================
-- END OF SCRIPT
-- =====================================================================
