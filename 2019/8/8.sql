begin;

create table input(input text);
\copy input from input

create table pixel(layer, x, y, z) as
select    (q.position - 1) / 25 / 6,
          (q.position - 1) % 25,
          (q.position - 1) / 25 % 6,
          q.z::int4
from      input, regexp_split_to_table(input.input, '') with ordinality as q(z, position);

------------
-- PART 1 --
------------

select      count(*) filter(where pixel.z = 1) * count(*) filter(where pixel.z = 2)
from        pixel
group by    pixel.layer
order by    count(*) filter(where pixel.z = 0)
limit       1;

------------
-- PART 2 --
------------

create or replace function first(anyelement, anyelement) returns anyelement as
$$
    select $1;
$$ language sql immutable strict;

create aggregate first
(
    sfunc    = first,
    basetype = anyelement,
    stype    = anyelement
);

with
pixel(x, y, z) as
(
    select      pixel.x, pixel.y, first(pixel.z order by pixel.layer) filter(where pixel.z != 2)
    from        pixel
    group by    pixel.x, pixel.y
)
select      string_agg(case pixel.z when 0 then '_' else '0' end, '' order by pixel.x)
from        pixel
group by    pixel.y
order by    pixel.y;

------------------------------------
-- PART 2 (preferred alternative) --
------------------------------------

with
pixel(x, y, z) as
(
    select      distinct on(pixel.x, pixel.y) pixel.x, pixel.y, pixel.z
    from        pixel
    where       pixel.z != 2
    order by    pixel.x, pixel.y, pixel.layer
)
select      string_agg(case pixel.z when 0 then '_' else '0' end, '' order by pixel.x)
from        pixel
group by    pixel.y
order by    pixel.y;

--------------------------
-- PART 2 (alternative) --
--------------------------

with
pixel(x, y, z) as
(
    select    distinct pixel.x, pixel.y, first_value(pixel.z) /*filter(where pixel.z != 2)*/ over(partition by pixel.x, pixel.y order by pixel.layer)
    from      pixel
    where     pixel.z != 2
)
select      string_agg(case pixel.z when 0 then '_' else '0' end, '' order by pixel.x)
from        pixel
group by    pixel.y
order by    pixel.y;

rollback;

--
-- Useful resources:
--
-- https://stackoverflow.com/a/34715134/8870331
-- https://stackoverflow.com/a/57975451/8870331
--
