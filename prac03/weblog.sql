-- COMP3311 24T1 Prac 03 Exercises
-- Written by: Jenny Hu (Mar 2024)

-- Originally come from UNSW COMP3311 18s1 Prac 04 Exercises


-- (V) Q1: how many page accesses on March 2

create or replace view Q1(nacc) as
select count(*) from Accesses where CAST(accTime AS varchar) ~ '.*-03-02.*'
;

-- sample ans:
-- create or replace view Q1(nacc) as
-- select count(*)
-- from   Accesses
-- where  accTime >= '2005-03-02 00:00:00' and accTime < '2005-03-03 00:00:00';



-- (V) Q2: how many times was the MessageBoard search facility used?

create or replace view Q2(nsearches) as
select count(*) from Accesses 
where (page like '_messageboard_' and params like '_state=search_')
;


-- (V) Q3: on which Tuba lab machines were there incomplete sessions?


create or replace view Q3(hostname) as
select distinct hostname from Hosts h 
join Sessions s on s.host = h.id 
where s.complete = 'f' and hostname ~ '^tuba.*\.orchestra\.cse\.unsw\.edu\.au';



-- (V) Q4: min,avg,max bytes transferred in page accesses

create or replace view Q4(min,avg,max) as
select min(nbytes), cast(avg(nbytes) as int), max(nbytes) from Accesses;
;

-- or avg(nbytes)::integer to cast datatype

-- (V) Q5: number of sessions from CSE hosts

create or replace view Q5(nhosts) as
select count(*) 
from Sessions s join Hosts h on s.host = h.id
where hostname ~ '.*cse\.unsw\.edu\.au$';
;


-- (V) Q6: number of sessions from non-CSE hosts

create or replace view Q6(nhosts) as
select count(*) 
from Sessions s join Hosts h on s.host = h.id
where hostname !~ '.*cse\.unsw\.edu\.au$';
;


-- (V) Q7: session id and number of accesses for the longest session?

create or replace view Q7(session,length) as 
select session, sum(nbytes) as length from Accesses
group by session
order by sum(nbytes) desc
limit 1
;

create or replace view Q7(session,length) as 
select session, count(*) as length from Accesses
group by session
order by count(*) desc
limit 1
;

-- (V) Q8: frequency of page accesses


create or replace view Q8(page,freq) as
select page, count(*) from Accesses
group by page
;


-- (V) Q9: frequency of module accesses


create or replace view Q9(module,freq) as
select split_part(page, '/', 1), count(*) from Accesses
group by split_part(page, '/', 1);
;


-- (V) Q10: "sessions" which have no page accesses

create or replace view Q10(session) as
select id from Sessions s
left join Accesses a on a.session = s.id
where a.seq is NULL
;


-- (V) Q11: hosts which are not the source of any sessions

create or replace view Q11(unused) as
select h.hostname
from Hosts h left join Sessions s on s.host = h.id
group by h.hostname
having count(s.id) = 0; -- cannot use count(*) -> since "left join" will left at least hostname itself even it don't have any session