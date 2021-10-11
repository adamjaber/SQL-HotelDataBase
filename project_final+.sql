
SET GLOBAL log_bin_trust_function_creators = 1;
create database hotel;
use  hotel;
CREATE TABLE rooms (
room_id INT  AUTO_INCREMENT PRIMARY KEY,
room_type VARCHAR(100)  NOT NULL,
room_beds int	,
room_price_perday INT  ,
room_status VARCHAR(100)  NOT NULL default 'empty'
);
select * from rooms;
drop table rooms ;
CREATE TABLE location (
room_id INT primary key  ,
location_bulding VARCHAR(100)  NOT NULL,
location_floor VARCHAR(100)  NOT NULL,
 FOREIGN KEY (room_id)
        REFERENCES rooms (room_id)
        ON UPDATE CASCADE  ON DELETE CASCADE 
);

select * from location;
drop table location;
CREATE TABLE clients (
client_id INT  AUTO_INCREMENT PRIMARY KEY ,
client_name VARCHAR(100)  NOT NULL,
client_address VARCHAR(100)  NOT NULL,
 client_phone VARCHAR(25) 

);
select * from clients;
drop table clients; 
CREATE TABLE workers (
worker_id INT  AUTO_INCREMENT PRIMARY KEY ,
worker_name VARCHAR(100)  NOT NULL,
worker_position VARCHAR(100)  NOT NULL,
worker_adress VARCHAR(100) 	,
 worker_phone VARCHAR(25) 

);
select * from workers;
drop table workers;
CREATE TABLE clean_room (
clean_id INT AUTO_INCREMENT PRIMARY KEY,
worker_id INT   ,
room_id INT ,
start_clean datetime NULL ,
end_clean datetime NULL ,
FOREIGN KEY (room_id)
        REFERENCES rooms (room_id)
        ON UPDATE CASCADE  ,
        
          FOREIGN KEY (worker_id)
        REFERENCES workers (worker_id)
        ON UPDATE CASCADE 
			

);
select * from clean_room;
drop table clean_room ;
CREATE TABLE orders (
order_id INT  AUTO_INCREMENT PRIMARY KEY ,
room_id INT  ,
client_id INT  ,
worker_id	INT	,
order_checkin DATE  NOT NULL,
order_checkout DATE  NOT NULL,
full_price int ,
 FOREIGN KEY (room_id)
        REFERENCES rooms (room_id)
        ON UPDATE CASCADE  ON DELETE CASCADE  ,
        
         FOREIGN KEY (client_id)
        REFERENCES clients (client_id)
        ON UPDATE CASCADE    ,
        
         FOREIGN KEY (worker_id)
        REFERENCES workers (worker_id)
        ON UPDATE CASCADE 
);
SELECT * FROM orders;
desc orders;
drop table orders; 
-- 1) Start/END clean Room PROCEDURE 
DELIMITER $$
CREATE PROCEDURE cleanRooms (  
IN room_id VARCHAR(20) ,
IN worker_id VARCHAR(20) ,
IN operation VARCHAR(20)
)
BEGIN

     IF  ((operation = 'start_clean') AND (select room_status from rooms R where R.room_id=room_id ) = 'wating for clean'  )   THEN
     begin
			INSERT INTO clean_room(worker_id,room_id,start_clean)
		VALUES(worker_id,room_id,now());
         
		end ;
      ELSEIF ( (operation = 'end_clean') AND (select room_status from rooms R where R.room_id=room_id ) = 'wating for clean'  )  THEN 
        begin
        UPDATE clean_room
			SET end_clean = now()
			WHERE   clean_room.room_id =room_id AND clean_room.worker_id =worker_id AND end_clean is NULL ;
            
               UPDATE rooms
			SET room_status ='empty'
			WHERE  rooms.room_id =room_id ;
			end ;
		END IF;
END $$
DELIMITER ;
drop procedure cleanRooms;
call cleanRooms(8,10,'start_clean');
call cleanRooms(8,10,'end_clean');
 -- 2) change status OF THE ROOMS PROCEDURE 
DELIMITER $$
CREATE PROCEDURE ordeingstatus (  
IN orderid VARCHAR(20) 
)
BEGIN
	DECLARE roomid INTEGER;
    select O.room_id INTO roomid from orders O where O.order_id = orderid; 
       UPDATE rooms
			SET room_status ='booked'
			WHERE  rooms.room_id =roomid ;
END  $$
DELIMITER ;
  drop procedure ordeingstatus ;
-- 3) STATUS OF ROOM FUNCTION
DELIMITER $$
CREATE FUNCTION
	show_status(roomid INTEGER) RETURNS VARCHAR(100)
BEGIN
-- DECLARE a_count INTEGER default 0;
DECLARE roomstatus VARCHAR(100);
select room_status INTO roomstatus from rooms R where R.room_id = roomid; 
RETURN roomstatus;

END$$
DELIMITER ;
DROP FUNCTION show_status ;
 select show_status(1); 
-- 1) View all rooms and their condition
select * from rooms as R 
inner join location as L
 on R.room_id=L.room_id ; 
--  2)  The list of the 10 most booked rooms
select O.room_id ,R.room_type ,COUNT(*) sumorders 
from orders O
 inner join rooms R 
 on R.room_id=O.room_id
GROUP BY room_id 
order by sumorders desc limit 10 ;

-- 3)  View all orders in the last two weeks
SELECT * FROM orders             
WHERE order_checkin >= DATE_SUB(CURDATE(), INTERVAL 14 DAY);


-- 4) Presenting the employee who cleaned the most rooms
 select w.worker_id,w.worker_name,w.worker_position,w.worker_adress,w.worker_phone ,COUNT(*) num_rooms_cleaned 
 from clean_room c
 inner join workers w 
 on w.worker_id=c.worker_id 
 GROUP BY c.worker_id 
 ORDER BY num_rooms_cleaned DESC limit 1;
 
 -- 5)  Viewing customer activity orders ordered.
 select  * from orders O inner join clients C on C.client_id=O.client_id where now() between O.order_checkin AND O.order_checkout;
 -- 6)  View repeat customers (more than one order.
  select C.client_id,C.client_name,C.client_address,C.client_phone , count(*) sumorders 
  from clients C
  inner join  orders O 
  on C.client_id=O.client_id  
  GROUP BY C.client_id 
  HAVING COUNT(*) > 1
  ;

-- 7)  Presentation of income by month
select extract(MONTH from orders.order_checkin   ) as month,sum(full_price) as total_value from orders
 group by month;

 select extract(MONTH from orders.order_checkin) as month,sum(full_price) as total_value from orders
  WHERE extract(MONTH from orders.order_checkin)='7'
 group by month  ;
--  inserts ROOM
INSERT INTO rooms (room_type ,room_beds,room_price_perday) VALUES
( 'suite ','2',500 ) ;
delete from rooms where room_id=6;
select * from rooms ;
-- INSERT LOCATION 
INSERT INTO location (room_id ,location_bulding,location_floor) VALUES
( 11,'L',2 ) ;
select * from location ;

-- INSERT CLIENTS
 INSERT INTO clients (client_name ,client_address,client_phone) VALUES
( 'C10','TEXAS', 597585259) ;

select * from clients ;
-- insert to worker
  INSERT INTO workers (worker_name ,worker_position,worker_adress,worker_phone) VALUES
( 'w10','cleaning','new york',5154523559) ;
select * from workers ;


-- insert orders
 DELIMITER $$
CREATE PROCEDURE makeorder (  
IN roomid INT,
IN clientid INT ,
IN workerid INT ,
IN startdate DATE,
IN enddate DATE
)
BEGIN
	DECLARE roomstatus varchar(25);
    select room_status INTO roomstatus from rooms where rooms.room_id = roomid; 
      IF ((roomstatus= 'empty') ) THEN
      BEGIN
       DECLARE priceD INTEGER;
       select room_price_perday INTO priceD from rooms R where R.room_id = roomid; 
	 INSERT INTO orders (room_id ,client_id,worker_id,order_checkin,order_checkout,full_price) VALUES
		( roomid,clientid,workerid,startdate,enddate,DATEDIFF(enddate, startdate)*priceD) ;
        
      END;
      
     END IF;
END  $$
DELIMITER ;
DROP procedure makeorder ;

-- INSERT ORDER
call makeorder(4,1,2,DATE_ADD(DATE(NOW()), INTERVAL 8 DAY),DATE_ADD(DATE(NOW()), INTERVAL 13 DAY));
  -- CHANGE STATUS BY ORDER ID
 select orders.order_id  from orders where orders.room_id = 4 ; 
call ordeingstatus(21);
       
-- update status for cleanig after the clients checkout 
   UPDATE rooms AS R  
	INNER JOIN orders AS O
       ON R.room_id = O.room_id
	SET  R.room_status = 'wating for clean'  
	WHERE O.order_checkout <= DATE(NOW()) and room_status !='empty' ;



-- THING FOR TEST

SELECT DATE_ADD(now(), INTERVAL 10 DAY);   
--  SELECT DATEDIFF('2020-10-30', '2020-10-01') AS 'Result';

-- select DATE(NOW());
 UPDATE rooms
			SET room_status ='empty'
			WHERE  rooms.room_id =5;
            delete from orders where worker_id=8;
            select  W.worker_position from workers W where W.worker_id=1;
            -- SELECT DATE_SUB(CURDATE(), INTERVAL 10 DAY);    
            
            UPDATE rooms
            set room_status='wating for clean' 
            where  room_id= 8;
            
            