CREATE DATABASE study;

USE study;

CREATE TABLE College(cName NVARCHAR(10),
state CHAR(2),
enrollment INT
);

INSERT INTO College VALUES ('Stanford','CA',15000),('Berkeley','CA',36000),('MIT','MA',10000),('Cornell','NY',21000);

CREATE TABLE Student(
sID INT ,
sName NVARCHAR(20),
GPA DEC(2,1),
sizeHS INT
);

INSERT INTO Student VALUES (123,'Amy',3.9,1000), (234,'Bob',3.6,1500), (345,'Craig',3.5,500), (456,'Doris',3.9,1000),
(567,'Edward',2.9,2000),  (678,'Fay',3.8,200),  (789,'Gary',3.4,800), (987,'Helen',3.7,800), (876,'Irene',3.9,400), 
(765,'Jay',2.9,1500), (654,'Amy',3.9,1000), (543,'Craig',3.4,2000);

CREATE TABLE Apply(sID INT NOT NULL,
cName NVARCHAR(10) NOT NULL,
major NVARCHAR(15) NOT NULL,
decision CHAR(1));

INSERT INTO Apply VALUES (123,'Stanford','CS','Y'),(123,'Stanford','EE','N'),
(123,'Berkeley','CS','Y'),(123,'Cornell','EE','Y'),(234,'Berkeley','biology','N'),(345,'MIT','bioengineering','Y'),
(345,'Cornell','bioengineering','N'),(345,'Cornell','CS','Y'),(345,'Cornell','EE','N'),(678,'Stanford','history','Y'),
(987,'Stanford','CS','Y'),(987,'Berkeley','CS','Y'),(876,'Stanford','CS','N'),(876,'MIT','biology','Y'),
(876,'MIT','marine biology','N'),(765,'Stanford','history','Y'),(765,'Cornell','history','N'),
(765,'Cornell','psychology','Y'),(543,'MIT','CS','N');

SELECT * FROM College;
SELECT * FROM Student;
SELECT * FROM Apply;

DROP TABLE College;
DROP TABLE Student;
DROP TABLE Apply;
/*notify cName*/
SELECT cName
FROM College, Apply
WHERE College.cName = Apply.cName
AND enrollment > 20000 AND major = 'CS';
  
SELECT *
FROM Student, College; /*similar CROSS JOIN*/

SELECT S1.sID, S1.sName, S1.GPA, S2.sID, S2.sName, S2.GPA
FROM Student S1, Student S2
WHERE S1.GPA = S2.GPA;/*and S1.sID <> S2.sID;*/ /*and S1.sID < S2.sID;*/

/*** Notice not sorted any more (SQLite), add order by cName ***/

SELECT cName AS NAME FROM College
UNION ALL
SELECT sName AS NAME FROM Student
ORDER BY NAME;

/*IDs of students who applied to both CS and EE Some systems don't support intersect*/
  SELECT DISTINCT A1.sID
FROM Apply A1, Apply A2
WHERE A1.sID = A2.sID AND A1.major = 'CS' AND A2.major = 'EE';

/*IDs of students who applied to CS but not EE Some systems don't support except*/
SELECT DISTINCT A1.sID
FROM Apply A1, Apply A2
WHERE A1.sID = A2.sID AND A1.major = 'CS' AND A2.major <> 'EE';

/**************************************************************
  IDs and names of students applying to CS
**************************************************************/

SELECT sID, sName
FROM Student
WHERE sID IN (SELECT sID FROM Apply WHERE major = 'CS');

/**************************************************************
  Same query written without 'In'
**************************************************************/
SELECT Student.sID, sName
FROM Student, Apply
WHERE Student.sID = Apply.sID AND major = 'CS';

/*** Remove duplicates ***/

SELECT DISTINCT Student.sID, sName
FROM Student, Apply
WHERE Student.sID = Apply.sID AND major = 'CS';

/**************************************************************
  Just names of students applying to CS
**************************************************************/

SELECT sName
FROM Student
WHERE sID IN (SELECT sID FROM Apply WHERE major = 'CS');

/**************************************************************
  Same query written without 'In'
**************************************************************/

SELECT sName
FROM Student, Apply
WHERE Student.sID = Apply.sID AND major = 'CS';

/*** Remove duplicates (still incorrect) ***/

SELECT DISTINCT sName
FROM Student, Apply
WHERE Student.sID = Apply.sID AND major = 'CS';

/*
Some row more or less than before
Should use with primary key
*/

SELECT DISTINCT Student.sID, GPA
FROM Student, Apply
WHERE Student.sID = Apply.sID AND major = 'CS';

/**************************************************************
  Colleges such that some other college is in the same state
  Ten cac truong dai hoc ma trong vung do con co cac truong dai hoc khac.
**************************************************************/

SELECT cName, state
FROM College C1
WHERE EXISTS (SELECT * FROM College C2
WHERE C2.state = C1.state);

/*** Fix error ***/

SELECT cName, state
FROM College C1
WHERE EXISTS (SELECT * FROM College C2
WHERE C2.state = C1.state AND C2.cName <> C1.cName);

/**************************************************************
  Biggest college (enrollment)
  Truong dai hoc co ung vien nop vao la dong nhat
**************************************************************/

/**************************************************************
  Highest GPA using ">= all"
**************************************************************/

SELECT sName, GPA
FROM Student
WHERE GPA >= ALL (SELECT GPA FROM Student);

/**************************************************************
  Higher GPA than all other students
**************************************************************/

SELECT sName, GPA
FROM Student S1
WHERE GPA > ALL (SELECT GPA FROM Student S2
                 WHERE S2.sID <> S1.sID);

/*** Similar: higher enrollment than all other colleges  ***/
SELECT cName
FROM College S1
WHERE enrollment > ALL (SELECT enrollment FROM College S2
                        WHERE S2.cName <> S1.cName);

/*** Same query using 'Not <= Any' ***/

/**************************************************************
  Students not from the smallest HS
**************************************************************/
SELECT sID, sName, sizeHS
FROM Student
WHERE sizeHS > ANY (SELECT sizeHS FROM Student);

/**************************************************************
  SUBQUERIES IN THE FROM AND SELECT CLAUSES
  Works for MySQL and Postgres
  SQLite doesn't support All
**************************************************************/

/**************************************************************
  Students whose scaled GPA changes GPA by more than 1
**************************************************************/

SELECT sID, sName, GPA, GPA*(sizeHS/1000.0) AS scaledGPA
FROM Student
WHERE GPA*(sizeHS/1000.0) - GPA > 1.0
   OR GPA - GPA*(sizeHS/1000.0) > 1.0;

/*** Can simplify using absolute value function ***/

SELECT sID, sName, GPA, GPA*(sizeHS/1000.0) AS scaledGPA
FROM Student
WHERE ABS(GPA*(sizeHS/1000.0) - GPA) > 1.0;

/*** Can further simplify using subquery in From ***/

SELECT *
FROM (SELECT sID, sName, GPA, GPA*(sizeHS/1000.0) AS scaledGPA
      FROM Student) G
WHERE ABS(scaledGPA - GPA) > 1.0;

/**************************************************************
  Colleges paired with the highest GPA of their applicants
  Truong dai hoc voi diem GPA cao nhat cua ung vien
**************************************************************/

SELECT College.cName, state, GPA
FROM College, Apply, Student
WHERE College.cName = Apply.cName
  AND Apply.sID = Student.sID
  AND GPA >= ALL
          (SELECT GPA FROM Student, Apply
           WHERE Student.sID = Apply.sID
             AND Apply.cName = College.cName);

/*** Add Distinct to remove duplicates ***/

SELECT DISTINCT College.cName, state, GPA
FROM College, Apply, Student
WHERE College.cName = Apply.cName
  AND Apply.sID = Student.sID
  AND GPA >= ALL
          (SELECT GPA FROM Student, Apply
           WHERE Student.sID = Apply.sID
             AND Apply.cName = College.cName);

/*** Use subquery in Select ***/

SELECT DISTINCT cName, state,
  (SELECT DISTINCT GPA
   FROM Apply, Student
   WHERE College.cName = Apply.cName
     AND Apply.sID = Student.sID
     AND GPA >= ALL
           (SELECT GPA FROM Student, Apply
            WHERE Student.sID = Apply.sID
              AND Apply.cName = College.cName)) AS GPA
FROM College;

/*** Now pair colleges with names of their applicants
    (doesn't work due to multiple rows in subquery result) ***/

SELECT DISTINCT cName, state,
  (SELECT DISTINCT sName
   FROM Apply, Student
   WHERE College.cName = Apply.cName
     AND Apply.sID = Student.sID) AS sName
FROM College;

/**************************************************************
  THREE-WAY INNER JOIN
  Application info: ID, name, GPA, college name, enrollment
**************************************************************/

SELECT Apply.sID, sName, GPA, Apply.cName, enrollment
FROM Apply, Student, College
WHERE Apply.sID = Student.sID AND Apply.cName = College.cName;

/*** Rewrite using three-way JOIN ***/
/*** Works in SQLite and MySQL but not Postgres ***/

SELECT Apply.sID, sName, GPA, Apply.cName, enrollment
FROM Apply JOIN Student JOIN College
ON Apply.sID = Student.sID AND Apply.cName = College.cName;

/*** Rewrite using binary JOIN ***/

SELECT Apply.sID, sName, GPA, Apply.cName, enrollment
FROM (Apply JOIN Student ON Apply.sID = Student.sID) JOIN College ON Apply.cName = College.cName;

/**************************************************************
  NATURAL JOIN WITH ADDITIONAL CONDITIONS
  Names and GPAs of students with sizeHS < 1000 applying to
  CS at Stanford
**************************************************************/

SELECT sName, GPA
FROM Student JOIN Apply
ON Student.sID = Apply.sID
WHERE sizeHS < 1000 AND major = 'CS' AND cName = 'Stanford';

/*** Rewrite using NATURAL JOIN ***/

SELECT sName, GPA
FROM Student NATURAL JOIN Apply
WHERE sizeHS < 1000 AND major = 'CS' AND cName = 'Stanford';

/*** USING clause considered safer ***/

SELECT sName, GPA
FROM Student JOIN Apply USING(sID)
WHERE sizeHS < 1000 AND major = 'CS' AND cName = 'Stanford';

/**************************************************************
  SELF-JOIN
  Pairs of students with same GPA
**************************************************************/

SELECT S1.sID, S1.sName, S1.GPA, S2.sID, S2.sName, S2.GPA
FROM Student S1, Student S2
WHERE S1.GPA = S2.GPA AND S1.sID < S2.sID;

/*** Rewrite using JOIN and USING (disallowed) ***/

SELECT S1.sID, S1.sName, S1.GPA, S2.sID, S2.sName, S2.GPA
FROM Student S1 JOIN Student S2 ON S1.sID < S2.sID USING(GPA);

/*** Without ON clause ***/

SELECT S1.sID, S1.sName, S1.GPA, S2.sID, S2.sName, S2.GPA
FROM Student S1 JOIN Student S2 USING(GPA)
WHERE S1.sID < S2.sID;

/**************************************************************
  LEFT OUTER JOIN
  Student application info: name, ID, college name, major
**************************************************************/

SELECT sName, sID, cName, major
FROM Student INNER JOIN Apply USING(sID);

/*** Include students who haven't applied anywhere ***/

SELECT sName, sID, cName, major
FROM Student LEFT OUTER JOIN Apply USING(sID);

/*** Abbreviation is LEFT JOIN ***/

SELECT sName, sID, cName, major
FROM Student LEFT JOIN Apply USING(sID);

/*** Using NATURAL OUTER JOIN ***/

SELECT sName, sID, cName, major
FROM Student NATURAL LEFT OUTER JOIN Apply;

/*** Can simulate without any JOIN operators ***/

SELECT sName, Student.sID, cName, major
FROM Student, Apply
WHERE Student.sID = Apply.sID
UNION
SELECT sName, sID, NULL, NULL
FROM Student
WHERE sID NOT IN (SELECT sID FROM Apply);

/*** Instead include applications without matching students ***/

INSERT INTO Apply VALUES (321, 'MIT', 'history', 'N');
INSERT INTO Apply VALUES (321, 'MIT', 'psychology', 'Y');
/*delete from Apply where siD = 321;*/

SELECT sName, sID, cName, major
FROM Apply NATURAL LEFT OUTER JOIN Student;

/**************************************************************
  FULL OUTER JOIN
  Student application info
**************************************************************/

/*** Include students who haven't applied anywhere ***/
/*** and applications without matching students ***/

SELECT sName, sID, cName, major
FROM Student FULL OUTER JOIN Apply USING(sID);

/*** Can simulate with LEFT and RIGHT outerjoins ***/
/*** Note UNION eliminates duplicates ***/

SELECT sName, sID, cName, major
FROM Student LEFT OUTER JOIN Apply USING(sID)
UNION
SELECT sName, sID, cName, major
FROM Student RIGHT OUTER JOIN Apply USING(sID);

/*** Can simulate without any JOIN operators ***/

SELECT sName, Student.sID, cName, major
FROM Student, Apply
WHERE Student.sID = Apply.sID
UNION
SELECT sName, sID, NULL, NULL
FROM Student
WHERE sID NOT IN (SELECT sID FROM Apply)
UNION
SELECT NULL, sID, cName, major
FROM Apply
WHERE sID NOT IN (SELECT sID FROM Student);

/**************************************************************
  THREE-WAY OUTER JOIN
  Not associative
**************************************************************/

CREATE TABLE T1 (A INT, B INT);
CREATE TABLE T2 (B INT, C INT);
CREATE TABLE T3 (A INT, C INT);
INSERT INTO T1 VALUES (1,2);
INSERT INTO T2 VALUES (2,3);
INSERT INTO T3 VALUES (4,5);

SELECT A,B,C
FROM (T1 NATURAL FULL OUTER JOIN T2) NATURAL FULL OUTER JOIN T3;

SELECT A,B,C
FROM T1 NATURAL FULL OUTER JOIN (T2 NATURAL FULL OUTER JOIN T3);

DROP TABLE T1;
DROP TABLE T2;
DROP TABLE T3;


/**************************************************************
  Lowest GPA of students applying to CS
  Ung vien co diem GPA thap nhat nop don vao CS
**************************************************************/

SELECT MIN(GPA)
FROM Student, Apply
WHERE Student.sID = Apply.sID AND major = 'CS';

/*** Average GPA of students applying to CS ***/

SELECT AVG(GPA)
FROM Student, Apply
WHERE Student.sID = Apply.sID AND major = 'CS';

/*** Fix incorrect counting of GPAs ***/

SELECT AVG(GPA)
FROM Student
WHERE sID IN (SELECT sID FROM Apply WHERE major = 'CS');
/*SELECT sID FROM Apply WHERE major = 'CS';*/


/**************************************************************
  Minimum + maximum GPAs of applicants to each college & major
  Diem GPA cao nhat vao thap nhat cua ung vien nop vao tung chuyen nganh cua moi truong dai hoc
**************************************************************/

SELECT cName, major, MIN(GPA), MAX(GPA)
FROM Student, Apply
WHERE Student.sID = Apply.sID
GROUP BY cName, major;

/*** First do query to picture grouping ***/

SELECT cName, major, GPA
FROM Student, Apply
WHERE Student.sID = Apply.sID
ORDER BY cName, major;

/**************************************************************
  NULL VALUES
  Works for SQLite, MySQL, Postgres
**************************************************************/

INSERT INTO Student VALUES (432, 'Kevin', NULL, 1500);
INSERT INTO Student VALUES (321, 'Lori', NULL, 2500);
/*delete from Student where GPA is null;*/
SELECT * FROM Student;

/*** Now either high or low GPA ***/

SELECT sID, sName, GPA
FROM Student
WHERE GPA > 3.5 OR GPA <= 3.5;

/*** Now use 'is null' ***/

SELECT sID, sName, GPA
FROM Student
WHERE GPA > 3.5 OR GPA <= 3.5 OR GPA IS NULL;

SELECT *
FROM Student
WHERE sID NOT IN (SELECT sID FROM Apply);