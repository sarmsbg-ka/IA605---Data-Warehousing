DELIMITER $$
-- create procedure
CREATE PROCEDURE p()

BEGIN

  DECLARE i INT DEFAULT 1;   
-- create a loop
myloop: LOOP

    SET i=i+1;

	SELECT CONCAT('I can count to ', i);

    IF i=10 then

            LEAVE myloop;

    END IF;

END LOOP myloop;



END;