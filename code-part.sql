---------------------------------------------------------------
---------------C.1 (b) Data Cleaning---------------------------
---------------------------------------------------------------

--1)--Is FLIGHTS table have any illegal entries  that is not in Aircraft table? 
select * from FLIGHTS 
where AIRCRAFTID NOT IN (select iatacode from OPFL.AIRCRAFTS); 

delete from FLIGHTS 
where AIRCRAFTID NOT IN (select iatacode from OPFL.AIRCRAFTS); 

--2)--is there any routes that has airlineid entry not existing in airlines table 
select * from ROUTES 
where airlineid NOT IN (select AIRlineid from AIRLINES); 

delete from ROUTES 
where airlineid NOT IN (select AIRlineid from AIRLINES); 

--3) --Check if there is any route with distance less than 0.
select * from ROUTES where DISTANCE <= 0;

delete from ROUTES where DISTANCE <= 0;

--4)--find if there are any illegal entries with negative passenger age
select * from passengers where AGE < 0;

delete from  passengers where AGE < 0;

--5)--deleting aircrafts with Erroneous IATACODE that does not match with requirements of 3 symbol length
select * from aircrafts where LENGTH(TRIM(IATACODE)) != 3;

delete from aircrafts where LENGTH(TRIM(IATACODE)) != 3;

--6) Finding all airlines with wrong IATA code ( unequal to 2 chars)
select * from airlines where LENGTH(TRIM(IATACODE)) != 2;

delete from airlines where LENGTH(TRIM(IATACODE)) != 2;

--7)--Finding entries with ICAO code that does not match 4 char length
select * from airlines where LENGTH(TRIM(ICAO)) !=3;

delete  from airlines where LENGTH(TRIM(ICAO)) !=3;

--8)--Finding entries with ICAO code that does not match 4 char length
Select * from airports where LENGTH(TRIM(ICAO)) != 4;

Delete from airports where LENGTH(TRIM(ICAO)) != 4;




-----------------------------------------------------------------
----------------C.2 Star Schema----------------------------------
-----------------------------------------------------------------

--------------------------------------------------------------------
--------------LEVEL_1 Star Schema, With Aggregation--------------
--------------------------------------------------------------------

-- Route Fact table
create table route_fact 
as select  s.city as Source_CityID, 
           d.city as Dest_CityID, 
           p.airlineid, 
           count(p.routeid) as total_number_of_routes, 
           sum(p.distance) as total_route_distance, 
           sum(p.servicecost) as total_service_cost
from Routes p, airports s, airports d
where p.sourceairportid = s.airportid
and p.destairportid = d.airportid
group by s.city, d.city, p.airlineid;

select * from route_fact;

--Create Source_City_DIM
create table Source_City_DIM
as select 
		  City,
		  Country,
		  TimeZone, 
		  DST
 from airports;
 
--Create Destination_City_DIM
create table Destination_City_DIM
as select 
		  City,
		  Country,
		  TimeZone, 
		  DST
from airports;

--Create Source_Country_DIM
create table Source_Country_DIM
as select 
		  Country,
		  TimeZone, 
		  DST
from airports;
 
--Create Destination_Country_DIM
create table Destination_Country_DIM
as select 
		  Country,
		  TimeZone, 
		  DST
from airports;
----------------------------------------------
--Creating Airline_DIM
Create Table Airline_DIM As
Select
   AL.AirlineID,
   AL.Name,
   1.0/count(PR.ServiceID) As Service_Weight,
   LISTAGG (PR.ServiceID, '_') Within Group
     (Order By PR.ServiceID) As StoreGroupList
From opfl.airlines AL, opfl.provides PR
Where AL.AirlineID = PR.AirlineID
Group By AL.AirlineID, AL.Name;
-------------------------------------------------

--Creating Airline Service Bridge and Service DIM

create table Airline_Service_Bridge
as select * from opfl.provides;

select * from Airline_Service_Bridge;
-------------------------------------------------
create table Service_DIM
as select * from opfl.Airline_Services;


select * from  Service_DIM;
-------------------------------------------------
----------------------------------------------
-----source airport DIM
create table source_airport_dim as 
select * from airports where airportid in (select sourceairportid from routes);

ALTER TABLE source_airport_dim
RENAME COLUMN airportid TO Sourceairportid;

ALTER TABLE source_airport_dim DROP COLUMN country;

select * from source_airport_dim;

----destination airport DIM
create table destination_airport_dim as
select * from airports where airportid in (select destairportid from routes);

ALTER TABLE destination_airport_dim
RENAME COLUMN airportid TO Destinationairportid;

ALTER TABLE destination_airport_dim DROP COLUMN country;

select * from destination_airport_dim;

---------------------------------------------------
---------------------------------------------------

----flight type dim
create table flight_type_dim
(FlightTypeID varchar2(10),
TypeName varchar2(50));

insert into flight_type_dim values('F1','Domestic');
insert into flight_type_dim values('F2','International');

------------------------------------------------------------------
--Creating Other DIM tables
------------------------------------------------------------------

--create Flight_class_DIM table
CREATE TABLE  Flight_Class_DIM
( class_id varchar2(3) NOT NULL,
  class_name varchar2(30) NOT NULL,
  CONSTRAINT classid_pk PRIMARY KEY (class_id)
);

--insert values
INSERT ALL
  INTO Flight_Class_DIM (class_id, class_name) VALUES ('C1', 'First Class')
  INTO Flight_Class_DIM (class_id, class_name) VALUES ('C2', 'Business Class')
  INTO Flight_Class_DIM (class_id, class_name) VALUES ('C3', 'Economy Class')
SELECT * FROM dual;

select * from Flight_Class_DIM;
select * from Route_DIM;

--Create table FlightDate_DIM
create table Flight_Date_DIM as
select distinct to_char(Flightdate, 'DDMMYY') as TimeID,
                to_char(Flightdate, 'DD') as Flight_Day,
                to_char(Flightdate, 'Month') as Flight_Month,
                to_char(Flightdate, 'YYYY') as Flight_Year
from Flights;

Select * from Flight_Date_DIM;
----------------------------------------------------------------

-- Create Temp Transaction Fact
create table temp_Trans_fact 
as select r.sourceairportid,
          r.destairportid,
          to_char(fl.flightdate,'DDMMYY') as flightdateid,
          tr.totalpaid,
          fl.fare, 
          a1.country as sourceCountry, 
          ap.country as destCountry,
          al.airlineid,
          tr.passid,
          tr.flightid,
          p.age 
from routes r, flights fl, transactions tr, airports a1, airports ap, airlines al, passengers p
where r.sourceairportid = a1.airportid 
and r.destairportid = ap.airportid 
and r.airlineid = al.airlineid 
and r.routeid = fl.routeid
and fl.flightid = tr.flightid 
and tr.passid = p.passid;

select * from temp_Trans_fact;
-----------------------------------------------------------
--Altering Transaction Fact

alter table temp_Trans_fact
add(class_id varchar2(20));

alter table temp_Trans_fact
add(flighttype_id varchar2(20));
--------------------------------------------------
update temp_Trans_fact 
set class_id='C1'
where totalpaid>= 2*fare;

update temp_Trans_fact
set class_id = 'C2'
where totalpaid>= 1.5*fare and totalpaid<2*fare;

update temp_Trans_fact
set class_id = 'C3'
where totalpaid < 1.5*fare;
-------------------------------------------------------

update temp_Trans_fact
set flighttype_id = 'F1'
where sourceCountry = destCountry;

update temp_Trans_fact
set flighttype_id = 'F2'
where sourceCountry != destCountry;
-------------------------------------------------------------
--Creating Transaction Fact


----------------------------------------------
--Creating Transaction Fact Table
drop table Transaction_fact;
create table Transaction_fact 
as select 
          flightdateid, 
          class_id, 
          flighttype_id, 
          sourceairportid, 
          destairportid,
          airlineid, 
          count(passid) as Total_Number_Of_transactions,
          count(passid) as number_of_passengers, 
          sum(totalpaid) as total_paid,
          sum(age) as total_passenger_age,
          sum(totalpaid - fare) as Agent_profit
from temp_Trans_fact
group by sourceairportid, destairportid,flightdateid, class_id, flighttype_id, airlineid;

select * from transaction_fact;
--------------------------------------------------------
----------------------------------------------------------

-- Memebership Sales Join Fact

-----------------------------------------------------------------------------------------------
---Passenger_DIM
create table passenger_dim
(Pass_type_ID varchar2(10),
Pass_type_desc varchar2(20));

insert into passenger_dim values('P1','Children');
insert into passenger_dim values('P2','Teenager');
insert into passenger_dim values('P3','Adult');
insert into passenger_dim values('P4','Elder');

select * from passenger_dim;
--
---Membership type DIM
create table Membership_type_DIM as 
select distinct 
            MembershiptypeID, 
            MembershipName, 
            membershipfee
from Membershiptype;

select * from membership_type_dim;
-----------------------------------------------

drop table Membership_Discount_DIM;

---Membership Discount DIM
create table Membership_Discount_DIM as
select 
     distinct m.membershiptypeid,
     p.startdate,
     p.enddate,
     p.discount
     
    from membershipjoinrecords m, promotion p
    where m.promotion = p.promotionid;

---------------------------------

---------------------------------
--membership join dim

create table Membership_Join_Date_DIM 
as select distinct to_char(joindate,'YYYYMM') as joindateid,
                   to_char(joindate,'YYYY') as year, 
                   to_char(joindate,'MM') as month
from membershipjoinrecords;

select * from  Membership_Join_Date_DIM;

----------------------------------------------
--Createing Memebership Sales fact
drop table MembershipSales_Fact_TMP;

create table MembershipSales_Fact_TMP as
select to_char(m.joindate, 'YYYYMM') as joindateid, 
       p.age, 
       m.membershipTypeID, 
       t.membershipfee, 
       m.passid
from  membershipjoinrecords m, passengers p, membershiptype t
where m.passid = p.passid 
and m.membershiptypeid = t.membershiptypeid;




alter table MembershipSales_Fact_TMP 
add(passenger_type_id varchar2(50));

update MembershipSales_Fact_TMP
set passenger_type_id = 'P1'
where age < 11;

update MembershipSales_Fact_TMP
set passenger_type_id = 'P2'
where age >= 11 and age <= 17;

update MembershipSales_Fact_TMP
set passenger_type_id = 'P3'
where age >= 18 and age <= 60;

update MembershipSales_Fact_TMP
set passenger_type_id = 'P4'
where age > 60 ;
---------------------------------------------
drop table Membership_Sales_Fact;

create table Membership_Sales_Fact 
as select joindateid, 
          passenger_type_id, 
          membershiptypeid, 
          sum(membershipfee) as total_membership_sale, 
          count(passid) as total_number_of_members
from MembershipSales_Fact_TMP 
group by joindateid, passenger_type_id, membershiptypeid;

select * from Membership_Sales_Fact;


--------------------------------------------------------------------
--------------LEVEL_0 Star Schema, Without Aggregation--------------
--------------------------------------------------------------------

---Create L0_Source_Airport_Dim table--
create table L0_source_airport_dim 
as select * from source_airport_dim ;


---Create L0_Destination_Airport_Dim table--
create table L0_Destination_airport_dim 
as select * from Destination_airport_dim ;

---Create L0_Source_City_DIM table--
create table L0_Source_City_DIM 
as select * from Source_City_DIM ;

---Create L0_Destination_City_DIM table--
create table L0_Destination_City_DIM 
as select * from Destination_City_DIM ;

---Create L0_Source_Country_DIM table--
create table L0_Source_Country_DIM 
as select * from Source_Country_DIM ;

---Create L0__Destination_DIM table--
create table L0_Destination_Country_DIM 
as select * from Destination_Country_DIM ;

--Create L0_L0_Airline_Service_Bridge table
create table L0_Airline_Service_Bridge
as select * from Airline_Service_Bridge;

--Create L0_Service_DIM table
create table L0_Service_DIM
as select * from Service_DIM;

--Create L0_Airline_DIM table
Create Table L0_Airline_DIM As
Select * from Airline_DIM;


--Level 0 Routr fact with no aggregation
create table L0_Route_fact
as select  sourceairportid, 
           destairportid, 
           airlineid,  
           distance as route_distance, 
           servicecost as service_cost
from Routes;


----L0_flight type dim
create table L0_Flight_type_dim
as select * from Flight_type_dim;


--create L0_Flight_class_DIM table
CREATE TABLE  L0_Flight_Class_DIM
as select * from Flight_Class_DIM;

--Create table FlightDate_DIM
create table L0_Flight_Date_DIM
as select * from Flight_Date_DIM;


-----Create L0_Temp_Trans_fact  table
create table L0_Temp_Trans_fact 
as select r.sourceairportid,
          r.destairportid,
          to_char(fl.flightdate,'DDMMYY') as flightdateid,
          tr.totalpaid,
          fl.fare, 
          a1.country as sourceCountry, 
          ap.country as destCountry,
          al.airlineid,
          p.passid, 
          p.age 
from routes r, flights fl, transactions tr, airports a1, airports ap, airlines al, passengers p
where r.sourceairportid = a1.airportid 
and r.destairportid = ap.airportid 
and r.airlineid = al.airlineid 
and r.routeid = fl.routeid
and fl.flightid = tr.flightid 
and tr.passid = p.passid;

alter table L0_Temp_Trans_fact
add(class_id varchar2(20));

commit;

alter table L0_Temp_Trans_fact
add(flighttype_id varchar2(20));
-----
update L0_Temp_Trans_fact 
set class_id='C1'
where totalpaid>= 2*fare;

update L0_Temp_Trans_fact
set class_id = 'C2'
where totalpaid>= 1.5*fare and totalpaid<2*fare;

update L0_Temp_Trans_fact
set class_id = 'C3'
where totalpaid < 1.5*fare;
-----

update L0_Temp_Trans_fact
set flighttype_id = 'F1'
where sourceCountry = destCountry;

update L0_Temp_Trans_fact
set flighttype_id = 'F2'
where sourceCountry != destCountry;

--Creating Transaction Fact Table
create table L0_Transaction_fact 
as select 
          passid, 
          flightdateid, 
          class_id, 
          flighttype_id, 
          sourceairportid, 
          destairportid,
          airlineid, 
          totalpaid,
          age,
          (totalpaid - fare) as Agent_profit
from Temp_Trans_fact;
 drop table L0_Transaction_fact ;
select * from L0_Transaction_fact ;

---Passenger_DIM
create table L0_Passenger_dim
as select * from Passenger_dim;

---Membership type DIM
create table L0_Membership_type_DIM 
as select * from Membership_type_DIM ;

-- membership join date dim
create table L0_Membership_Join_Date_DIM 
as select * from Membership_Join_Date_DIM ;


-------memb discount
---Membership Discount DIM
create table L0_Membership_Discount_DIM as
select 
     m.membershiptypeid,
     p.startdate,
     p.enddate,
     p.discount
     
    from membershipjoinrecords m, promotion p
    where m.promotion = p.promotionid;
    
------------------------------------------------------------
-----create Passenger Dec DIM (for lowering the level of aggregation)
create table Passenger_Desc_DIM
as select distinct passid from passengers;




----------------------------------------------------
--Createing Memebership Sales TMP fact


create table L0_MembershipSales_Fact_TMP as
select to_char(m.joindate,'YYYYMM') as joindateid, 

       p.age, 
       m.membershipTypeID, 
       r.promotionid, 
       t.membershipfee, 
       m.passid, 
       r.discount
from  membershipjoinrecords m, promotion r, passengers p, membershiptype t
where m.passid = p.passid 
and m.promotion = r.promotionid 
and m.membershiptypeid = t.membershiptypeid;

alter table L0_MembershipSales_Fact_TMP 
add(passenger_type_id varchar2(50));

update L0_MembershipSales_Fact_TMP
set passenger_type_id = 'P1'
where age < 11;

update L0_MembershipSales_Fact_TMP
set passenger_type_id = 'P2'
where age >= 11 and age <= 17;

update L0_MembershipSales_Fact_TMP
set passenger_type_id = 'P3'
where age >= 18 and age <= 60;

update L0_MembershipSales_Fact_TMP
set passenger_type_id = 'P4'
where age > 60 ;

-----------------
create table L0_Membership_Sales_Fact 
as select 
          passid, 
          joindateid,
          passenger_type_id, 
          membershiptypeid, 
          promotionid, 
          (membershipfee * (1- discount)) as membership_sale
from L0_MembershipSales_Fact_TMP; 

select * from L0_Membership_Sales_Fact ;



----------------------------------------------------------
----------------------------------------------------------
----------------3. Basic Report------------------------------
----------------------------------------------------------
--report1

select * from (select 
                    a.sourceairportid,
                    round(sum(t.age)/count(t.passid),1) as average_age,
                    rank() over (order by (sum(t.age)/count(t.passid)) desc) as rankage
from L0_source_airport_dim a, L0_Source_City_dim c, L0_transaction_fact t, L0_flight_class_dim fc
where a.sourceairportid = t.sourceairportid
and t.class_id = fc.class_id
and a.city = c.city
and c.country = 'Australia'
and fc.class_name = 'Business Class'
group by a.sourceairportid )
where rownum <=3;

---------------------
--report 2

select mj.month, sum(ms.passid) as newly_joined_member
from L0_Membership_Join_Date_Dim mj, L0_Membership_Sales_Fact ms, L0_Passenger_dim p, L0_membership_type_dim mt
where mj.joindateid= ms.joindateid
and p.pass_type_id=ms.passenger_type_id
and ms.membershiptypeid=mt.membershiptypeid
and mt.membershipname = 'Gold'
and p.pass_type_desc = 'Adult'
and mj.year = 2013
Group by mj.month 
order by sum(ms.passid);


---------------------
--report3
select fd.Flight_year,
          DECODE(GROUPING(ft.typename), 1, 'ANY Types', ft.typename) as FLIGHT_TYPE,
          DECODE(GROUPING(fc.class_name), 1, 'ANY Classes', fc.class_name) as FLIGHT_CLASS,
          DECODE(GROUPING(sc.country), 1, 'Any Country', sc.country)as sourceCountry,
          DECODE(GROUPING(dc.country), 1, 'Any Country', dc.country)as destinationCountry,
          sum(t.total_number_of_transactions) as  number_of_transactions,
          round(sum(t.agent_profit)/sum(t.total_number_of_transactions),1) as average_agent_profit
from      destination_airport_dim d,
          source_airport_dim s,
          source_city_dim sc,
          destination_city_dim dc,
          transaction_fact t,
          flight_type_dim ft,
          flight_class_dim fc,
          flight_date_dim fd

where d.destinationairportID = t.DestairportID
      and s.sourceairportid = t.sourceairportID
      and s.city = sc.city
      and d.city = dc.city
		  and t.flighttype_id = ft.flighttypeid
		  and t.class_id = fc.class_id
		  and fd.timeid = t.flightdateid

group by fd.Flight_year, cube(ft.typename, fc.class_name, sc.country , dc.country)
order by fd.Flight_year;

----------------------------------------------------
--------4. Advanced Reports using OLAP Query--------
----------------------------------------------------
--report 4
select    DECODE(GROUPING(a.name) , 1, 'Any Airline', a.name) as AIRLINE,
          DECODE(GROUPING(s.name), 1, 'Any Source Airport', s.name) as SOURCEAIRPORT,
          DECODE(GROUPING(d.name),  1, 'Any Dest Airport', d.name) as DESTAIRPORT,
          sum(f.agent_profit) as SALES
from               
          transaction_fact f,
          airline_dim a,
          source_airport_dim s,
          destination_airport_dim d

where     a.airlineid=f.airlineid
and       f.sourceairportid=s.sourceairportid          
and       f.destairportid = d.destinationairportid

GROUP BY CUBE (a.name,
               s.name, 
               d.name)
order by a.name;

--------------------------
-- Report 5

select  t.membershipname, 
        j.month, 
        to_char(sum(f.total_membership_sale * NVL(d.discount,1)), '9,999,999,999' ) as SALES,
        to_char(sum(sum(f.total_membership_sale)) OVER (ORDER BY t.membershipname, j.month  ROWS UNBOUNDED PRECEDING), '9,999,999,999') AS CUM_SALES ,
        to_CHAR (AVG(SUM(f.total_membership_sale)) OVER (ORDER BY t.membershipname, j.month ROWS 2 PRECEDING), '9,999,999,999') AS MOVING_MONTH_AVG 
        
from
        membership_sales_fact f, 
        membership_join_date_dim j, 
        membership_type_dim t,
        membership_Discount_dim d
        
where f.membershiptypeID=t.membershiptypeid
and   f.joindateid=j.joindateid
and t.membershiptypeid = 'M2'
and d.membershiptypeid = t.membershiptypeid
and j.year = 2009
and to_char(d.startdate, 'YY') = 09
and d.membershiptypeid = 'M2'
group by  t.membershipname, j.month;


----------------
--Report 6

select  dc.country, 
        dc.city, 
        sum(f.total_number_of_routes)as Number_Incoming_Routes,
        RANK() OVER ( PARTITION BY dc.country ORDER BY SUM(f.total_number_of_routes) DESC) AS RANK_BY_COUNTRY
        
from route_fact f,destination_city_dim dc
where f.source_cityid = dc.CITY
group by dc.country, dc.city;



-----------------------------------------------------------
----------------5. Acess Pan  -----------------------------
-----------------------------------------------------------
-------(c) The excution plan of the original query
set autotrace on;

-------------------
----Report 3
Explain plan for
select fd.Flight_year,
          DECODE(GROUPING(ft.typename), 1, 'ANY Types', ft.typename) as FLIGHT_TYPE,
          DECODE(GROUPING(fc.class_name), 1, 'ANY Classes', fc.class_name) as FLIGHT_CLASS,
          DECODE(GROUPING(sc.country), 1, 'Any Country', sc.country)as sourceCountry,
          DECODE(GROUPING(dc.country), 1, 'Any Country', dc.country)as destinationCountry,
          sum(t.total_number_of_transactions) as  number_of_transactions,
          round(sum(t.agent_profit)/sum(t.total_number_of_transactions),1) as average_agent_profit
from      destination_airport_dim d,
          source_airport_dim s,
          source_city_dim sc,
          destination_city_dim dc,
          transaction_fact t,
          flight_type_dim ft,
          flight_class_dim fc,
          flight_date_dim fd

where d.destinationairportID = t.DestairportID
      and s.sourceairportid = t.sourceairportID
      and s.city = sc.city
      and d.city = dc.city
		  and t.flighttype_id = ft.flighttypeid
		  and t.class_id = fc.class_id
		  and fd.timeid = t.flightdateid

group by fd.Flight_year, cube(ft.typename, fc.class_name, sc.country , dc.country)
order by fd.Flight_year;
---------
select *
from table(dbms_xplan.display);





-------------------
----Report 4

Explain plan for
select    DECODE(GROUPING(a.name) , 1, 'Any Airline', a.name) as AIRLINE,
          DECODE(GROUPING(s.name), 1, 'Any Source Airport', s.name) as SOURCEAIRPORT,
          DECODE(GROUPING(d.name),  1, 'Any Dest Airport', d.name) as DESTAIRPORT,
          sum(f.agent_profit) as SALES
from               
          transaction_fact f,
          airline_dim a,
          source_airport_dim s,
          destination_airport_dim d

where     a.airlineid=f.airlineid
and       f.sourceairportid=s.sourceairportid          
and       f.destairportid = d.destinationairportid

GROUP BY CUBE (a.name,
               s.name, 
               d.name)
order by a.name;
----------------
select *
from table(dbms_xplan.display);




-- Report 5
Explain plan for
select  t.membershipname, 
        j.month, 
        to_char(sum(f.total_membership_sale * NVL(d.discount,1)), '9,999,999,999' ) as SALES,
        to_char(sum(sum(f.total_membership_sale)) OVER (ORDER BY t.membershipname, j.month  ROWS UNBOUNDED PRECEDING), '9,999,999,999') AS CUM_SALES ,
        to_CHAR (AVG(SUM(f.total_membership_sale)) OVER (ORDER BY t.membershipname, j.month ROWS 2 PRECEDING), '9,999,999,999') AS MOVING_MONTH_AVG 
        
from
        membership_sales_fact f, 
        membership_join_date_dim j, 
        membership_type_dim t,
        membership_Discount_dim d
        
where f.membershiptypeID=t.membershiptypeid
and   f.joindateid=j.joindateid
and t.membershiptypeid = 'M2'
and d.membershiptypeid = t.membershiptypeid
and j.year = 2009
and to_char(d.startdate, 'YY') = 09
and d.membershiptypeid = 'M2'
group by  t.membershipname, j.month;
----------------------------
select *
from table(dbms_xplan.display);


-------------------------------------
--Report 6
Explain plan for
select  dc.country, 
        dc.city, 
        sum(f.total_number_of_routes)as Number_Incoming_Routes,
        RANK() OVER ( PARTITION BY dc.country ORDER BY SUM(f.total_number_of_routes) DESC) AS RANK_BY_COUNTRY
        
from route_fact f,destination_city_dim dc
where f.source_cityid = dc.CITY
group by dc.country, dc.city;
----------------------------
select *
from table(dbms_xplan.display);

 
 
 
 
 ----------------------------------------------------------
 -----------------(e) New SQL  ----------------------------
 ----------------------------------------------------------

 
 -----Report 3
Explain plan for
select    /*+ USE_MERGE (d s sc dc t ft fc fd) */ 
          fd.Flight_year,
          DECODE(GROUPING(ft.typename), 1, 'ANY Types', ft.typename) as FLIGHT_TYPE,
          DECODE(GROUPING(fc.class_name), 1, 'ANY Classes', fc.class_name) as FLIGHT_CLASS,
          DECODE(GROUPING(sc.country), 1, 'Any Country', sc.country)as sourceCountry,
          DECODE(GROUPING(dc.country), 1, 'Any Country', dc.country)as destinationCountry,
          sum(t.total_number_of_transactions) as  number_of_transactions,
          round(sum(t.agent_profit)/sum(t.total_number_of_transactions),1) as average_agent_profit
from      destination_airport_dim d,
          source_airport_dim s,
          source_city_dim sc,
          destination_city_dim dc,
          transaction_fact t,
          flight_type_dim ft,
          flight_class_dim fc,
          flight_date_dim fd

where d.destinationairportID = t.DestairportID
      and s.sourceairportid = t.sourceairportID
      and s.city = sc.city
      and d.city = dc.city
		  and t.flighttype_id = ft.flighttypeid
		  and t.class_id = fc.class_id
		  and fd.timeid = t.flightdateid

group by fd.Flight_year, cube(ft.typename, fc.class_name, sc.country , dc.country)
order by fd.Flight_year;
---------
select *
from table(dbms_xplan.display);
 
 
 
------------------------------------------- 
--report 4
Explain plan for
select    /*+ USE_MERGE (f a s d) */ 
          DECODE(GROUPING(a.name) , 1, 'Any Airline', a.name) as AIRLINE,
          DECODE(GROUPING(s.name), 1, 'Any Source Airport', s.name) as SOURCEAIRPORT,
          DECODE(GROUPING(d.name),  1, 'Any Dest Airport', d.name) as DESTAIRPORT,
          sum(f.agent_profit) as SALES
from               
          transaction_fact f,
          airline_dim a,
          source_airport_dim s,
          destination_airport_dim d

where     a.airlineid=f.airlineid
and       f.sourceairportid=s.sourceairportid          
and       f.destairportid = d.destinationairportid

GROUP BY CUBE (a.name,
               s.name, 
               d.name)
order by a.name;
----------------
select *
from table(dbms_xplan.display);

 
 
--------------------------------------------------------------
-- Report 5
--Explain plan for
select   /*+ USE_MERGE (j f t d) */
        t.membershipname, 
        j.month, 
        to_char(sum(f.total_membership_sale * NVL(d.discount,1)), '9,999,999,999' ) as SALES,
        to_char(sum(sum(f.total_membership_sale)) OVER (ORDER BY t.membershipname, j.month  ROWS UNBOUNDED PRECEDING), '9,999,999,999') AS CUM_SALES ,
        to_CHAR (AVG(SUM(f.total_membership_sale)) OVER (ORDER BY t.membershipname, j.month ROWS 2 PRECEDING), '9,999,999,999') AS MOVING_MONTH_AVG 
        
from
        membership_sales_fact f, 
        membership_join_date_dim j, 
        membership_type_dim t,
        membership_Discount_dim d
        
where f.membershiptypeID=t.membershiptypeid
and   f.joindateid=j.joindateid
and t.membershiptypeid = 'M2'
and d.membershiptypeid = t.membershiptypeid
and j.year = 2009
and to_char(d.startdate, 'YY') = 09
and d.membershiptypeid = 'M2'
group by  t.membershipname, j.month;
----------------------------
select *
from table(dbms_xplan.display);
 
 
 
 
 
-------------------------------------
--Report 6
Explain plan for
select  /*+ USE_MERGE (dc f) */
        dc.country, 
        dc.city, 
        sum(f.total_number_of_routes)as Number_Incoming_Routes,
        RANK() OVER ( PARTITION BY dc.country ORDER BY SUM(f.total_number_of_routes) DESC) AS RANK_BY_COUNTRY
        
from route_fact f,destination_city_dim dc
where f.source_cityid = dc.CITY
group by dc.country, dc.city;
----------------------------
select *
from table(dbms_xplan.display);Final
 
 
 
 
 
 
 