begin;

create table input(input text);
\copy input from input

with recursive
direct_path(source, target) as
(
    select    substring(input.input from 1 for 3), substring(input.input from 5)
    from      input
),
path(source, target, length) as
(
    select        direct_path.source, direct_path.target, 1
    from          direct_path
    union all
    select        path.source, direct_path.target, path.length + 1
    from          path
    cross join    direct_path
    where         path.target = direct_path.source
)
select        count(*)
from          path
union all
select        min(path_1.length + path_2.length) - 2
from          path as path_1
cross join    path as path_2
where         (path_1.source, path_1.target, path_2.target) = (path_2.source, 'YOU', 'SAN');

rollback;
