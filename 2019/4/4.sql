begin;

select    count(*)
from      generate_series(1, 9) as a, -- actually, we can start at 2, as this can be derived from the leftmost digit
          generate_series(a, 9) as b,
          generate_series(b, 9) as c,
          generate_series(c, 9) as d,
          generate_series(d, 9) as e,
          generate_series(e, 9) as f
where     a * 100000 + b * 10000 + c * 1000 + d * 100 + e * 10 + f between 272091 and 815432 and
          exists(select from (values (a), (b), (c), (d), (e), (f)) as digit group by digit having count(*) >= 2);

select    count(*)
from      generate_series(1, 9) as a,
          generate_series(a, 9) as b,
          generate_series(b, 9) as c,
          generate_series(c, 9) as d,
          generate_series(d, 9) as e,
          generate_series(e, 9) as f
where     a * 100000 + b * 10000 + c * 1000 + d * 100 + e * 10 + f between 272091 and 815432 and
          exists(select from (values (a), (b), (c), (d), (e), (f)) as digit group by digit having count(*) = 2);

rollback;
