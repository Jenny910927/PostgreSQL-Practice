-- COMP3311 24T1 Prac 04 Exercises
-- Written by: Jenny Hu (Mar 2024)

-- Originally come from UNSW COMP3311 13s2 Prac 05 Exercises



-- (V) Q1. What beers are made by Toohey's?

create or replace view Q1 as
select b.name
from  Beers b join Brewers br on b.brewer = br.id
where br.name = 'Toohey''s'
;

-- (V) Q2. Show beers with headings "Beer", "Brewer".

create or replace view Q2 as
select b.name as beerName, br.name as brewerName
from Beers b join Brewers br on b.brewer = br.id
;

-- (V) Q3. Find the brewers whose beers John likes.
create or replace view Q3 as
select br.name
from Brewers br join Beers b on b.brewer = br.id
where b.id in (
    select beer from Likes L join Drinkers D on L.drinker = D.id
    where D.name = 'John'
)
;

-- (V) Q4. How many different beers are there?

create or replace view Q4 as
select count(distinct id)
from Beers
;

-- (V) Q5. How many different brewers are there?

create or replace view Q5 as
select count(distinct id)
from Brewers
;

-- (V) Q6. Find pairs of beers by the same manufacturer
--     (but no pairs like (a,b) and (b,a), and no (a,a))

create or replace view Q6 as
select b1.name as beer1, b2.name as beer2
from  Beers b1
join Beers b2 on b1.brewer = b2.brewer
where  b1.id < b2.id
;

-- (V) Q7. How many beers does each brewer make?

create or replace view Q7 as
select br.name as brewer, count(*) as nbeers
from  Brewers br
left join Beers b on b.brewer = br.id
group by br.name
;

-- (V) Q8. Which brewer makes the most beers?

create or replace view Q8 as
select brewer
from Q7
where  nbeers = (select max(nbeers) from Q7)
;

-- (V) Q9. Beers that are the only one by their brewer.

create or replace view numOfBeers as
select brewer, count(*) as numberOfBeers
from Beers
group by brewer;


create or replace view Q9 as
select name as beer from Beers
where brewer in (
    select brewer from numOfBeers
    where numberOfBeers = 1
);

-- (V) Q10. Beers sold at bars where John drinks.


create or replace view Q10 as
select distinct(b.name) as beer
from   Frequents f
         join Drinkers d on (d.id=f.drinker)
         join Sells s on (s.bar=f.bar)
         join Beers b on (b.id=s.beer)
where  d.name = 'John'
;





-- (V) Q11. Bars where either Gernot or John drink.


create or replace view drinkerBars as
select d.name as drinker, b.name as bar
from  Bars b 
full join Frequents f on (b.id = f.bar)
full join Drinkers d on (d.id = f.drinker)
;



create or replace view Q11 as
select distinct(b.name) as bar
from  Bars b 
join Frequents f on f.bar = b.id
join Drinkers d on f.drinker = d.id
where d.name in ('Gernot', 'John')
;

create or replace view Q11 as
select distinct(bar)
from  (select bar from drinkerBars where drinker = 'John') 
union (select bar from drinkerBars where drinker = 'Gernot')
;


-- -- Q12. Bars where both Gernot and John drink.

create or replace view Q12 as
select distinct(bar)
from  (select bar from drinkerBars where drinker = 'John') 
intersect (select bar from drinkerBars where drinker = 'Gernot')
;
-- -- Q13. Bars where John drinks but Gernot doesn't

create or replace view Q13 as
select distinct(bar)
from  (select bar from drinkerBars where drinker = 'John') 
except (select bar from drinkerBars where drinker = 'Gernot')
;

-- (V) Q14. What is the most expensive beer?

create or replace view Q14 as
select b.name
from Sells s 
join Beers b on b.id = s.beer
where s.price = ( select max(price) from Sells )
;



-- (V) Q15. Find bars that serve New at the same price
--      as the Coogee Bay Hotel charges for VB.

create or replace view PriceBarBeer as
select s.price, Bars.name as bar, b.name as beer
from Sells s
join Bars on Bars.id = s.bar
join Beers b on b.id = s.beer
;

create or replace view Q15 as
select bar
from PriceBarBeer
where price = (
    select price from PriceBarBeer 
    where bar = 'Coogee Bay Hotel' and beer = 'Victoria Bitter'
) and beer = 'New'
;

-- (V) Q16. Find the average price of common beers
--      ("common" = served in more than two hotels).

create or replace view Q16 as
select beer, round(avg(price)::numeric, 2)
from PriceBarBeer
group by beer
having count(bar) > 2
order by round(avg(price)::numeric, 2)
;

-- (V) Q17. Which bar sells 'New' cheapest?

create or replace view Q17 as
select bar
from  PriceBarBeer
where price = (
    select min(price) from PriceBarBeer 
    where beer = 'New'
) 
and beer = 'New'
;

-- (V) Q18. Which bar is most popular? (Most drinkers)

create or replace view NumDrinkerOfBar as
select bar, count(*)
from drinkerBars
group by bar;

create or replace view Q18 as
select bar
from NumDrinkerOfBar
where count = (
    select max(count)
    from NumDrinkerOfBar
)
;

-- (V) Q19. Which bar is least popular? (May have no drinkers)

create or replace view Q19 as
select bar
from NumDrinkerOfBar
where count = (
    select min(count)
    from NumDrinkerOfBar
)
;

-- (V) Q20. Which bar is most expensive? (Highest average price)
create or replace view AvgPriceBar as
select bar, round(avg(price)::numeric, 2) as avgprice
from PriceBarBeer
group by bar;

create or replace view Q20 as
select bar
from AvgPriceBar
where avgprice = (
    select max(avgprice) from AvgPriceBar
);


-- (star) Q21. Which beers are sold at all bars?

create or replace view Q21 as
select b.name as beer
from Beers b
where not exists (
    (select id from Bars)
    except 
    (select bar from Sells s
    where s.beer = b.id)
)
;

-- (V) Q22. Price of cheapest beer at each bar?

create or replace view Q22 as
select bar, min(price)::numeric(5,2) as min_price
from PriceBarBeer
group by bar
order by min(price)
;

-- (V) Q23. Name of cheapest beer at each bar?

create or replace view Q23 as
select bar, beer
from PriceBarBeer p1
where price = (select min_price from Q22 where Q22.bar = p1.bar)
;

-- (V) Q24. How many drinkers are in each suburb?

create or replace view Q24 as
select addr, count(*)
from Drinkers
group by addr
;

-- (V) Q25. How many bars in suburbs where drinkers live?
--      (Must include suburbs with no bars)

create or replace view Q25 as
select Q24.addr, count(Bars.name) as "#bars"
from Q24
left join Bars on Bars.addr = Q24.addr
group by Q24.addr
order by count(Bars.name) desc
;