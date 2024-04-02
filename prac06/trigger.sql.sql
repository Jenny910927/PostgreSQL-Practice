-- COMP3311 24T1 Prac06 Exercise
-- Written by: Jenny Hu (Apr 2024)

-- Originally come from UNSW COMP3311 18s1 Prac 07 Exercise

create or replace function UpdateRating() 
    returns trigger
as $$
begin
    if (TG_OP = 'INSERT') then
        update Beer set nratings = nratings + 1 where Beer.id = new.beer;
        update Beer set totrating = totrating + new.score where Beer.id = new.beer;
        update Beer set rating = totrating / nratings where Beer.id = new.beer;
        return new;
    
    elsif (TG_OP = 'DELETE') then
        update Beer set nratings = nratings - 1 where Beer.id = old.beer;
        update Beer set totrating = totrating - old.score where Beer.id = old.beer;
        update Beer set rating = 
            case when nratings <> 0 then totrating / nratings 
            else NULL end
            where Beer.id = old.beer;
        return new;

    elsif (TG_OP = 'UPDATE') then
        update Beer set totrating = totrating - old.score + new.score where Beer.id = new.beer;
        update Beer set rating = totrating / nratings where Beer.id = new.beer;
        return new;

    end if;
end;
$$ language plpgsql;

create or replace trigger RatingCheck 
after insert or update or delete on Ratings
for each row execute procedure UpdateRating();


-- My test case
-- <insert>
insert into Ratings values (1, 4, 4);
insert into Ratings values (2, 4, 2);

-- <Update>
update Ratings set score = 1 where taster = 1 and beer = 4;


-- <delete>
delete from Ratings where taster = 1 and beer = 4;
delete from Ratings where taster = 2 and beer = 4;


select * from Beer where id = 4;
