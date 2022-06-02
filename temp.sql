-- for testing purposes only
/*
SELECT * FROM ZOiS ORDER BY KodKonta;
INSERT INTO ZOiS (KodKonta, OpisKonta) VALUES ('020', 'test');
*/

---------------------------------------------------
-- KROK 1
-- dodaj wszystkich rodzic�w, kt�rych brak
---------------------------------------------------
-- a) dodaj indeks aby nie dodawa� istniej�cych ju� wpis�w
CREATE UNIQUE INDEX idx_KodKonta ON ZOiS(KodKonta);
INSERT OR IGNORE INTO ZOiS (KodKonta)
SELECT * FROM
    (
    WITH split(chunk, str, KodKonta) AS (
        SELECT '', KodKonta, KodKonta FROM ZOiS
        UNION ALL SELECT
        chunk || '-' || substr(str, 0, instr(str, '-')),
        substr(str, instr(str, '-')+1),
        KodKonta
        FROM split WHERE instr(str, '-') > 0
    ) 
    SELECT trim(chunk,'-') Rodzic FROM split WHERE chunk<>'' ORDER BY split.KodKonta
) GROUP BY Rodzic;



---------------------------------------------------
-- KROK 3
-- dodaj i wype�nij kolumn� Rodzic
---------------------------------------------------
-- a) dodaj kolumn�
ALTER TABLE ZOiS ADD COLUMN Rodzic TEXT;
-- b) poniewa� dla SQLite < 3.33 nie mo�na wykonywa� kwerendy UPDATE ... FROM, utw�rz tabel� pomocnicz�
CREATE TABLE temp AS
WITH split(chunk, str, KodKonta) AS (
    SELECT '', KodKonta, KodKonta FROM ZOiS
    UNION ALL SELECT
    substr(str, 0, instr(str, '-')),
    substr(str, instr(str, '-')+1),
    KodKonta
    FROM split WHERE instr(str, '-') > 0
) 
SELECT trim(group_concat(chunk,'-'),'-') Rodzic, KodKonta FROM split WHERE chunk<>'' GROUP BY KodKonta;

-- b) zaktualizuj tabel� rodzic�w
UPDATE ZOiS SET Rodzic = (SELECT Rodzic FROM temp WHERE temp.KodKonta = ZOiS.KodKonta);
DROP TABLE temp;

-- poka� wynik
SELECT Rodzic, KodKonta, OpisKonta FROM ZOiS ORDER BY KodKonta;



















-- DEPRECATED ---------------------------------------------------------------------------

-- poka� rodzic�w dla ka�dego konta w ZOiS ('X-' pokazuje te� konta 1-go poziomu)
WITH split(chunk, str, KodKonta) AS (
    SELECT '', 'X-'||KodKonta, KodKonta FROM ZOiS
    UNION ALL SELECT
    substr(str, 0, instr(str, '-')),
    substr(str, instr(str, '-')+1),
    KodKonta
    FROM split WHERE instr(str, '-') > 0
) 
SELECT trim(group_concat(chunk,'-'),'X-') Rodzic, KodKonta FROM split WHERE chunk<>'' GROUP BY KodKonta;











-- wymie� wszystkich rodzic�w (r�wnie� tych istniej�cych) - deprecated
SELECT * FROM
    (
    WITH split(chunk, str, KodKonta) AS (
        SELECT '', KodKonta, KodKonta FROM ZOiS
        UNION ALL SELECT
        chunk || '-' || substr(str, 0, instr(str, '-')),
        substr(str, instr(str, '-')+1),
        KodKonta
        FROM split WHERE instr(str, '-') > 0
    ) 
    SELECT trim(chunk,'-') Rodzic FROM split
    WHERE chunk<>'' 
    -- poni�sza linia powoduje niepokazywanie istniej�cych w ZOiS kod�w, ale dzia�a wolno
    -- AND NOT EXISTS (SELECT 1 FROM ZOiS WHERE KodKonta = trim(chunk,'-'))
    ORDER BY split.KodKonta
) GROUP BY Rodzic;


-- �mieci --

WITH split(num, chunk, str, KodKonta) AS (
    SELECT 0, '', KodKonta||'-', KodKonta FROM ZOiS
    UNION ALL SELECT
    num+1,
    substr(str, 0, instr(str, '-')),
    substr(str, instr(str, '-')+1),
    KodKonta
    FROM split WHERE str<>''
) 
-- SELECT num, chunk, KodKonta FROM split WHERE chunk!='' ORDER BY KodKonta;
SELECT MAX(num) AS level,
       GROUP_CONCAT(CASE num WHEN 1 THEN chunk ELSE '' END, '') AS chunk1,
       GROUP_CONCAT(CASE num WHEN 2 THEN chunk ELSE '' END, '') AS chunk2,
       GROUP_CONCAT(CASE num WHEN 3 THEN chunk ELSE '' END, '') AS chunk3,
       GROUP_CONCAT(CASE num WHEN 4 THEN chunk ELSE '' END, '') AS chunk4,
       GROUP_CONCAT(CASE num WHEN 5 THEN chunk ELSE '' END, '') AS chunk5,
       KodKonta 
  FROM split WHERE chunk<>'' GROUP BY KodKonta;