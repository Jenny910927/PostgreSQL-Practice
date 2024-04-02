-- UNSW COMP3311 24T1 Prac05 Exercise
-- Written by: Jenny Hu (Apr 2024)

-- Originally come from UNSW COMP3311 09s1 Prac Exercise
-- Practice design by: John Shepherd (April 2009)


-- (V) 1. AllRatings view 

create or replace view AllRatings(taster,beer,brewer,rating) as
	select t.given, b.name, br.name, r.score
	from Ratings r
	join Taster t on r.taster = t.id
	join Beer b on r.beer = b.id
	join Brewer br on b.brewer = br.id
	order by t.given, r.score desc
;

-- (V) 2. John's favourite beer and corresponding brewer

create or replace view JohnsFavouriteBeer(brewer,beer) as
	select br.name, b.name
	from Ratings r
	join Taster t on r.taster = t.id
	join Beer b on r.beer = b.id
	join Brewer br on b.brewer = br.id
	where t.given = 'John' and r.score = (
		select max(score)
		from Ratings r
		join Taster t on r.taster = t.id
		where t.given = 'John'
	)
;


-- (V) 3. X's favourite beer
-- Remarks: 
--   1. Use setof since there may be more than one returned tuples (having same rating)
--   2. Use $1 to differentiate taster and AllRatings.taster

create type BeerInfo as (brewer text, beer text);

create or replace function FavouriteBeer(taster text) 
returns setof BeerInfo
as $$
	select brewer, beer
	from AllRatings
	where taster = $1 and rating = (
		select max(rating) 
		from AllRatings
		where taster = $1
	);
$$ language sql
;



-- (V) 4. Beer style
-- Remarks: case-insentitive
create or replace function BeerStyle(brewer text, beer text) returns text
as $$
	select s.name
	from Beer b
	join BeerStyle s on b.style = s.id
	join Brewer br on b.brewer = br.id
	where br.name ~* $1 and b.name ~* $2;
$$ language sql
;

create or replace function BeerStyle1(brewer text, beer text) returns text
as $$
declare
	style text;
begin
	select s.name into style
	from Beer b
	join BeerStyle s on b.style = s.id
	join Brewer br on b.brewer = br.id
	where br.name ~* $1 and b.name ~* $2;
	return style;
end;
$$ language plpgsql
;



-- (V) 5. Taster address
-- Remarks: pay attention to NULL when concat strings
create or replace function TasterAddress(taster text) returns text
as $$
	select case 
		when loc.state is NULL then loc.country
		when loc.country is NULL then loc.state
		when loc.state is not NULL and loc.country is not NULL then loc.state||', '||loc.country
		else NULL
		end as tasteraddress
	from   Taster t, Location loc
	where  t.given = $1 and t.livesIn = loc.id
$$ language sql
;

create or replace function TasterAddress(taster text) returns text
as $$
declare 
	state TEXT;
	country TEXT;
begin
	select loc.state, loc.country into state, country
	from   Taster t, Location loc
	where  t.given = $1 and t.livesIn = loc.id;

	if (state is NULL) then
		return country;
	elsif (country is NULL) then
		return state;
	else
		return state || ', ' || country;
	end if;
end;
$$ language plpgsql
;


-- (V) 6. BeerSummary function
create or replace function BeerTaster(beerName TEXT) returns TEXT
as $$
declare
	nameList TEXT := '';
	name TEXT;
begin
	for name in (
		select taster from AllRatings
		where beer = beerName and taster is not NULL
	)
	loop
		if(length(nameList) = 0) then
			nameList := name;
		else
			nameList := nameList || ', ' || name;
		end if;
	end loop;
	return nameList;
end;
$$ language plpgsql;


create or replace function BeerSummary() returns text
as $$
declare
	summary TEXT := '';
	info record;
begin
	for info in (
		select beer, round(avg(rating)::numeric, 1) as rating, BeerTaster(beer) as tasters
		from AllRatings
		group by beer
		order by beer
	)
	loop 
		summary := summary || E'\n' || 
					'Beer:    ' || info.beer || E'\n' ||
					'Rating:  ' || info.rating || E'\n' ||
					'Tasters: ' || info.tasters || E'\n';
	end loop;
	return summary;
end;
$$ language plpgsql;



-- (V) 7. Concat aggregate

create or replace function join (name1 TEXT, name2 TEXT) returns TEXT
as $$
begin
	if (name1 = '' or name1 is NULL) then
		return name2;
	elsif (name2 = '' or name2 is NULL) then 
		return name1;
	else
		return name1 || ',' || name2;
	end if;
end;
$$ language plpgsql;

create aggregate concat (TEXT)(
	stype = TEXT,
	initcond = '',
	sfunc = join
);

create aggregate concat (... replace by base type ...)
(
	stype     =,
	initcond  = ... replace by initial state ... ,
	sfunc     = ... replace by name of state transition function ...,
	finalfunc = ... replace by name of finalisation function ...
);


-- (V) 8. BeerSummary view

create or replace view BeerSummary(beer,rating,tasters)
as
	select beer, round(avg(rating)::numeric, 1), concat(taster)
	from AllRatings
	group by beer
;
