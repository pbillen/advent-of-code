begin;

create function v(int8, int8) returns int8 as
$$
    select case when $1 < $2 then 1::int8 when $1 = $2 then 0::int8 else -1::int8 end;
$$
language sql immutable;

create function gcd(int8, int8) returns int8 as
$$
    with recursive
    stack(iteration, x, y) as
    (
        select    0, abs($1), abs($2)
        union all
        select    stack.iteration + 1, stack.y, stack.x % stack.y
        from      stack
        where     stack.y > 0
    )
    select      stack.x
    from        stack
    order by    stack.iteration desc
    limit       1;
$$
language sql immutable;

create function lcm(int8, int8) returns int8 as
$$
    select $1 * $2 / gcd($1, $2);
$$
language sql immutable;

with recursive
stack(iteration, px, py, pz, vx, vy, vz, ix, iy, iz) as
(
    select                1, '{14,9,-6,4}'::int8[], '{9,11,14,-4}'::int8[], '{14,6,-4,-3}'::int8[], '{0,0,0,0}'::int8[], '{0,0,0,0}'::int8[], '{0,0,0,0}'::int8[], null::int8, null::int8, null::int8
    union all
    select                stack.iteration + 1, _.px, _.py, _.pz, _.vx, _.vy, _.vz, _.ix, _.iy, _.iz
    from                  stack
    cross join lateral    (
                              with recursive
                              p(x, y, z) as
                              (
                                  select    array[stack.px[1]+v.x[1],stack.px[2]+v.x[2],stack.px[3]+v.x[3],stack.px[4]+v.x[4]],
                                            array[stack.py[1]+v.y[1],stack.py[2]+v.y[2],stack.py[3]+v.y[3],stack.py[4]+v.y[4]],
                                            array[stack.pz[1]+v.z[1],stack.pz[2]+v.z[2],stack.pz[3]+v.z[3],stack.pz[4]+v.z[4]]
                                  from      v
                              ),
                              v(x, y, z) as
                              (
                                  select    array[stack.vx[1]+v(stack.px[1],stack.px[2])+v(stack.px[1],stack.px[3])+v(stack.px[1],stack.px[4]),stack.vx[2]+v(stack.px[2],stack.px[1])+v(stack.px[2],stack.px[3])+v(stack.px[2],stack.px[4]),stack.vx[3]+v(stack.px[3],stack.px[1])+v(stack.px[3],stack.px[2])+v(stack.px[3],stack.px[4]),stack.vx[4]+v(stack.px[4],stack.px[1])+v(stack.px[4],stack.px[2])+v(stack.px[4],stack.px[3])],
                                            array[stack.vy[1]+v(stack.py[1],stack.py[2])+v(stack.py[1],stack.py[3])+v(stack.py[1],stack.py[4]),stack.vy[2]+v(stack.py[2],stack.py[1])+v(stack.py[2],stack.py[3])+v(stack.py[2],stack.py[4]),stack.vy[3]+v(stack.py[3],stack.py[1])+v(stack.py[3],stack.py[2])+v(stack.py[3],stack.py[4]),stack.vy[4]+v(stack.py[4],stack.py[1])+v(stack.py[4],stack.py[2])+v(stack.py[4],stack.py[3])],
                                            array[stack.vz[1]+v(stack.pz[1],stack.pz[2])+v(stack.pz[1],stack.pz[3])+v(stack.pz[1],stack.pz[4]),stack.vz[2]+v(stack.pz[2],stack.pz[1])+v(stack.pz[2],stack.pz[3])+v(stack.pz[2],stack.pz[4]),stack.vz[3]+v(stack.pz[3],stack.pz[1])+v(stack.pz[3],stack.pz[2])+v(stack.pz[3],stack.pz[4]),stack.vz[4]+v(stack.pz[4],stack.pz[1])+v(stack.pz[4],stack.pz[2])+v(stack.pz[4],stack.pz[3])]
                              ),
                              i(x, y, z) as
                              (
                                  select    case when stack.ix is null then (case when p.x = '{14,9,-6,4}'::int8[] then stack.iteration + 1 else null end) else stack.ix end,
                                            case when stack.iy is null then (case when p.y = '{9,11,14,-4}'::int8[] then stack.iteration + 1 else null end) else stack.iy end,
                                            case when stack.iz is null then (case when p.z = '{14,6,-4,-3}'::int8[] then stack.iteration + 1 else null end) else stack.iz end
                                  from      p
                              )
                              select     p.x, p.y, p.z, v.x, v.y, v.z, i.x, i.y, i.z
                              from       p, v, i
                          ) _(px, py, pz, vx, vy, vz, ix, iy, iz)
    where                 stack.ix is null or stack.iy is null or stack.iz is null
)
select      lcm(lcm(stack.ix, stack.iy), stack.iz)
from        stack
order by    stack.iteration desc
limit       1;

rollback;
