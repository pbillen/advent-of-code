begin;

create table input(line int4 generated always as identity, input text);
\copy input(input) from input

create table pixel(x, y, z) as
select        q.x::int4 - 1, input.line::int4 - 1, q.z
from          input
cross join    regexp_split_to_table(input.input, '') with ordinality as q(z, x);

with
ray(x1, y1, x2, y2, angle) as
(
    select        pixel_1.x, pixel_1.y, pixel_2.x, pixel_2.y,
                  atan2d(pixel_2.y - pixel_1.y, pixel_2.x - pixel_1.x)
    from          pixel as pixel_1
    cross join    pixel as pixel_2
    where         pixel_1.z = '#' and
                  pixel_2.z = '#' and
                  (pixel_1.x, pixel_1.y) != (pixel_2.x, pixel_2.y)
),
center(x, y, c) as
(
    select      ray.x1, ray.y1, count(distinct(ray.angle))
    from        ray
    group by    ray.x1, ray.y1
    order by    count(distinct(ray.angle)) desc
    limit       1
),
target(x, y, position) as
(
    select    target.x, target.y, row_number() over(order by target.position)
    from      (
                  select    target.x, target.y, (row_number() over(partition by target.angle order by target.distance), target.angle)
                  from      (
                                select        ray.x2, ray.y2,
                                              -- normalize angles, so we consider the north first
                                              case when ray.angle >= -90 then ray.angle else ray.angle + 360 end,
                                              abs(ray.x2 - center.x) + abs(ray.y2 - center.y)
                                from          center
                                cross join    ray
                                where         (center.x, center.y) = (ray.x1, ray.y1)
                            ) as target(x, y, angle, distance)
              ) as target(x, y, position)
)
------------
-- PART 1 --
------------
(
    select    center.c
    from      center
)
------------
-- PART 2 --
------------
union all
(
    select    100 * target.x + target.y
    from      target
    where     target.position = 200
);

rollback;
