/*
 * Name:        <Your Full Name>
 * Student ID:  <Your Student ID>
 * Assignment:  Homework 5 - University Queries (INS3064)
 * Date:        2026-10-11
 */

USE university_db;

/*
 * Query 1: List All Students
 * Description: Retrieves every column of every row from the students table
 *              to get a quick overview of all registered students.
 * Expected Output: One row per student with all student columns.
 */
SELECT * FROM students;

/*
 * +----+------------+-----------+------+
 * | id | first_name | last_name | gpa  |
 * +----+------------+-----------+------+
 * |  1 | An         | Nguyen    | 3.50 |
 * |  2 | Bich       | Tran      | 3.80 |
 * ...
 * +----+------------+-----------+------+
 * (N rows)  -- replace with your real output
 */

/*
 * Query 2: Students with GPA Above 3.0
 * Description: Filters students using a comparison operator (>) to find
 *              those with a GPA greater than 3.0.
 * Expected Output: Only students whose GPA is above 3.0.
 */
SELECT id, first_name, last_name, gpa
FROM students
WHERE gpa > 3.0;

/*
 * +----+------------+-----------+------+
 * | id | first_name | last_name | gpa  |
 * +----+------------+-----------+------+
 * |  1 | An         | Nguyen    | 3.50 |
 * |  2 | Bich       | Tran      | 3.80 |
 * ...
 * +----+------------+-----------+------+
 * (N rows)
 */

/*
 * Query 3: Courses in a Department with 3+ Credits
 * Description: Combines conditions with AND/OR: courses with at least 3 credits
 *              that belong to department 1, or any course with 4 or more credits.
 * Expected Output: Course code, title, credits and department id of matching courses.
 */
SELECT course_code, title, credits, department_id
FROM courses
WHERE (department_id = 1 AND credits >= 3)
   OR credits >= 4;

/*
 * +-------------+--------------------------+---------+---------------+
 * | course_code | title                    | credits | department_id |
 * +-------------+--------------------------+---------+---------------+
 * | CS101       | Introduction to Computing|       3 |             1 |
 * ...
 * +-------------+--------------------------+---------+---------------+
 * (N rows)
 */

/*
 * Query 4: Students Ordered by Last Name
 * Description: Sorts students by last name ascending, then first name ascending
 *              as a tie-breaker.
 * Expected Output: All students in alphabetical order of last name.
 */
SELECT id, last_name, first_name
FROM students
ORDER BY last_name ASC, first_name ASC;

/*
 * +----+-----------+------------+
 * | id | last_name | first_name |
 * +----+-----------+------------+
 * |  5 | Le        | Cuong      |
 * |  1 | Nguyen    | An         |
 * ...
 * +----+-----------+------------+
 * (N rows)
 */

/*
 * Query 5: Top 3 Highest-Graded Enrollments
 * Description: Orders enrollments by grade descending and uses LIMIT 3
 *              to return only the three best grades.
 * Expected Output: Exactly 3 rows with the highest grades.
 */
SELECT id, student_id, course_id, grade
FROM enrollments
ORDER BY grade DESC
LIMIT 3;

/*
 * +----+------------+-----------+-------+
 * | id | student_id | course_id | grade |
 * +----+------------+-----------+-------+
 * |  4 |          2 |         1 |  9.50 |
 * |  7 |          3 |         2 |  9.20 |
 * |  1 |          1 |         1 |  9.00 |
 * +----+------------+-----------+-------+
 * (3 rows)
 */

/*
 * Query 6: Courses Whose Title Contains "Introduction"
 * Description: Uses LIKE with the % wildcard to find courses whose title
 *              contains the word "Introduction" anywhere.
 * Expected Output: Introductory courses only.
 */
SELECT course_code, title
FROM courses
WHERE title LIKE '%Introduction%';

/*
 * +-------------+---------------------------+
 * | course_code | title                     |
 * +-------------+---------------------------+
 * | CS101       | Introduction to Computing |
 * ...
 * +-------------+---------------------------+
 * (N rows)
 */

/*
 * Query 7: Number of Students per Department
 * Description: Uses COUNT with GROUP BY to count how many students belong to
 *              each department. Aliases make the output columns readable.
 * Expected Output: One row per department with its student count.
 */
SELECT department_id,
       COUNT(*) AS total_students
FROM students
GROUP BY department_id;

/*
 * +---------------+----------------+
 * | department_id | total_students |
 * +---------------+----------------+
 * |             1 |              4 |
 * |             2 |              3 |
 * +---------------+----------------+
 * (N rows)
 */

/*
 * Query 8: Departments with More Than 2 Courses
 * Description: Groups courses by department and uses HAVING to keep only
 *              departments that offer more than 2 courses.
 * Expected Output: Departments with 3 or more courses and their course count.
 */
SELECT department_id,
       COUNT(*)     AS course_count,
       SUM(credits) AS total_credits
FROM courses
GROUP BY department_id
HAVING COUNT(*) > 2;

/*
 * +---------------+--------------+---------------+
 * | department_id | course_count | total_credits |
 * +---------------+--------------+---------------+
 * |             1 |            4 |            13 |
 * +---------------+--------------+---------------+
 * (N rows)
 */

/*
 * Query 9: Courses with Instructor Names
 * Description: Joins the courses and instructors tables to show
 *              each course title alongside the instructor who teaches it.
 * Expected Output: A list of course titles with instructor full names.
 */
SELECT
    c.course_code,
    c.title        AS course_title,
    CONCAT(i.first_name, ' ', i.last_name) AS instructor_name
FROM courses c
JOIN instructors i ON c.instructor_id = i.id
ORDER BY c.course_code;

/*
 * +-------------+---------------------------+-----------------+
 * | course_code | course_title              | instructor_name |
 * +-------------+---------------------------+-----------------+
 * | CS101       | Introduction to Computing | Ngoc Nguyen     |
 * ...
 * +-------------+---------------------------+-----------------+
 * (N rows)
 */

/*
 * Query 10: Full Enrollment Report (4-table JOIN)
 * Description: Joins enrollments, students, courses and semesters to list
 *              each enrollment with student name, course title, semester and grade.
 * Expected Output: One row per enrollment with readable names instead of ids.
 */
SELECT
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    c.title                                AS course_title,
    sem.name                               AS semester,
    e.grade
FROM enrollments e
JOIN students  s   ON e.student_id  = s.id
JOIN courses   c   ON e.course_id   = c.id
JOIN semesters sem ON e.semester_id = sem.id
ORDER BY sem.name, student_name;

/*
 * +--------------+---------------------------+-------------+-------+
 * | student_name | course_title              | semester    | grade |
 * +--------------+---------------------------+-------------+-------+
 * | An Nguyen    | Introduction to Computing | Fall 2025   |  9.00 |
 * ...
 * +--------------+---------------------------+-------------+-------+
 * (N rows)
 */
