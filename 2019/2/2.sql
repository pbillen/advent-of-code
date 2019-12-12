begin;

create table program(position int4, code int4);

insert into    program(position, code)
select         program.position - 1, program.code
from           (
                   select    program.position, program.code::int4
                   from      regexp_split_to_table('1,0,0,3,1,1,2,3,1,3,4,3,1,5,0,3,2,10,1,19,1,19,9,23,1,23,6,27,2,27,13,31,1,10,31,35,1,10,35,39,2,39,6,43,1,43,5,47,2,10,47,51,1,5,51,55,1,55,13,59,1,59,9,63,2,9,63,67,1,6,67,71,1,71,13,75,1,75,10,79,1,5,79,83,1,10,83,87,1,5,87,91,1,91,9,95,2,13,95,99,1,5,99,103,2,103,9,107,1,5,107,111,2,111,9,115,1,115,6,119,2,13,119,123,1,123,5,127,1,127,9,131,1,131,10,135,1,13,135,139,2,9,139,143,1,5,143,147,1,13,147,151,1,151,2,155,1,10,155,0,99,2,14,0,0', ',')
                                 with ordinality as program(code, position)
               ) as program(position, code);

create function code(program[], int4) returns int4 as
$$
    select program.code from unnest($1) as program where program.position = $2;
$$
language sql immutable;

create function code(int4, int4, int4) returns int4 as
$$
    select case when $1 = 1 then $2 + $3 else $2 * $3 end;
$$
language sql immutable;

create function calculate(noun int4, verb int4) returns int4 as
$$
    with recursive
    stack(iteration, position, program) as
    (
        select     0, 0, array_agg(row(program.position, case when program.position = 1 then noun when program.position = 2 then verb else program.code end)::program)
        from       program
        union all
        select     stack.iteration + 1, stack.position + 4, q.program
        from       stack,
        lateral    (
                       select    array_agg(row(program.position, case when program.position = code(stack.program, stack.position + 3) then code(code(stack.program, stack.position), code(stack.program, code(stack.program, stack.position + 1)), code(stack.program, code(stack.program, stack.position + 2))) else program.code end)::program)
                       from      unnest(stack.program) as program
                   ) as q(program)
        where      code(stack.program, stack.position) != 99
    )
    select      (stack.program[1]).code
    from        stack
    order by    stack.iteration desc
    limit       1;
$$
language sql stable;

select calculate(12, 2);
select 100 * noun + verb from generate_series(0, 99) as noun, generate_series(0, 99) as verb where calculate(noun, verb) = 19690720;

rollback;

-- In hindsight:
--
-- (1) To pass the current state to the next iteration, `int[]` (instead of `program[]`) was a better choice. This way, we can lookup by index,
--     instead of having to unnest the array.
-- (2) A function `array_set(...)` could be useful. This way, we can avoid having to unnest the array just to change some values here and there.
-- (3) Instead, we could have passed a json document to the next iteration. See https://github.com/xocolatl/advent-of-code/blob/master/2019/dec02.sql
--     for an example implementation. This way, we can lookup and update directly.
