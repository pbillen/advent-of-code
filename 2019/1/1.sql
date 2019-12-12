begin;

create table module(mass int4);
\copy module from input

with
_module(fuel) as
(
    select    module.mass / 3 - 2
    from      module
    where     module.mass / 3 - 2 > 0
)
select    sum(_module.fuel)
from      _module;

with recursive
_module(fuel) as
(
    select    module.mass / 3 - 2
    from      module
    where     module.mass / 3 - 2 > 0
    union all
    select    _module.fuel / 3 - 2
    from      _module
    where     _module.fuel / 3 - 2 > 0
)
select    sum(_module.fuel)
from      _module;

rollback;
