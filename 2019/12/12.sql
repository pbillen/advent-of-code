begin;

create function gcd(int8, int8) returns int8 as
$$
    with recursive
    stack(i, x, y) as
    (
        select    0, abs($1), abs($2)
        union all
        select    stack.i + 1, stack.y, stack.x % stack.y
        from      stack
        where     stack.y > 0
    )
    select      stack.x
    from        stack
    order by    stack.i desc
    limit       1;
$$
language sql immutable;

create function lcm(int8, int8) returns int8 as
$$
    select $1 * $2 / gcd($1, $2);
$$
language sql immutable strict;

create aggregate lcm
(
    sfunc    = lcm,
    basetype = int8,
    stype    = int8
);

create function process(int8[]) returns table(i int, m int8, p int8, v int8) as
$$
    with recursive
    stack(i, m, p, v) as
    (
        select    1, _.m, _.p, 0::int8
        from      unnest($1) with ordinality as _(p, m)
        union all
        (
            with
            _stack as
            (
                select stack.* from stack
            )
            select      stack_1.i + 1,
                        stack_1.m,
                        stack_1.p + (stack_1.v + sum(case when stack_1.p < stack_2.p then 1 when stack_1.p = stack_2.p then 0 else -1 end)),
                        stack_1.v + sum(case when stack_1.p < stack_2.p then 1 when stack_1.p = stack_2.p then 0 else -1 end)
            from        _stack as stack_1, _stack as stack_2
            where       (select array_agg(_stack.p order by _stack.m) from _stack) != $1 or
                        stack_1.i = 1
            group by    stack_1.i, stack_1.m, stack_1.p, stack_1.v
        )
    )
    select    stack.i, stack.m, stack.p, stack.v
    from      stack;
$$ language sql stable;

with recursive
x(i, m, p, v) as
(
    select * from process('{14,9,-6,4}')
),
y(i, m, p, v) as
(
    select * from process('{9,11,14,-4}')
),
z(i, m, p, v) as
(
    select * from process('{14,6,-4,-3}')
)
select    lcm(_.i)
from      (select max(x.i) from x union all select max(y.i) from y union all select max(z.i) from z) as _(i);

rollback;
