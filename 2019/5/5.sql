begin;

create table program
(
    position    int4,
    code        int4
);

insert into    program(position, code)
select         program.position - 1, program.code
from           (
                   select    program.position, program.code::int4
                   from      regexp_split_to_table('3,225,1,225,6,6,1100,1,238,225,104,0,1101,65,39,225,2,14,169,224,101,-2340,224,224,4,224,1002,223,8,223,101,7,224,224,1,224,223,223,1001,144,70,224,101,-96,224,224,4,224,1002,223,8,223,1001,224,2,224,1,223,224,223,1101,92,65,225,1102,42,8,225,1002,61,84,224,101,-7728,224,224,4,224,102,8,223,223,1001,224,5,224,1,223,224,223,1102,67,73,224,1001,224,-4891,224,4,224,102,8,223,223,101,4,224,224,1,224,223,223,1102,54,12,225,102,67,114,224,101,-804,224,224,4,224,102,8,223,223,1001,224,3,224,1,224,223,223,1101,19,79,225,1101,62,26,225,101,57,139,224,1001,224,-76,224,4,224,1002,223,8,223,1001,224,2,224,1,224,223,223,1102,60,47,225,1101,20,62,225,1101,47,44,224,1001,224,-91,224,4,224,1002,223,8,223,101,2,224,224,1,224,223,223,1,66,174,224,101,-70,224,224,4,224,102,8,223,223,1001,224,6,224,1,223,224,223,4,223,99,0,0,0,677,0,0,0,0,0,0,0,0,0,0,0,1105,0,99999,1105,227,247,1105,1,99999,1005,227,99999,1005,0,256,1105,1,99999,1106,227,99999,1106,0,265,1105,1,99999,1006,0,99999,1006,227,274,1105,1,99999,1105,1,280,1105,1,99999,1,225,225,225,1101,294,0,0,105,1,0,1105,1,99999,1106,0,300,1105,1,99999,1,225,225,225,1101,314,0,0,106,0,0,1105,1,99999,108,226,226,224,102,2,223,223,1005,224,329,101,1,223,223,1107,226,677,224,1002,223,2,223,1005,224,344,101,1,223,223,8,226,677,224,102,2,223,223,1006,224,359,101,1,223,223,108,677,677,224,1002,223,2,223,1005,224,374,1001,223,1,223,1108,226,677,224,1002,223,2,223,1005,224,389,101,1,223,223,1007,677,677,224,1002,223,2,223,1006,224,404,1001,223,1,223,1108,677,677,224,102,2,223,223,1006,224,419,1001,223,1,223,1008,226,677,224,102,2,223,223,1005,224,434,101,1,223,223,107,677,677,224,102,2,223,223,1006,224,449,1001,223,1,223,1007,226,677,224,102,2,223,223,1005,224,464,101,1,223,223,7,677,226,224,102,2,223,223,1005,224,479,101,1,223,223,1007,226,226,224,102,2,223,223,1005,224,494,101,1,223,223,7,677,677,224,102,2,223,223,1006,224,509,101,1,223,223,1008,677,677,224,1002,223,2,223,1006,224,524,1001,223,1,223,108,226,677,224,1002,223,2,223,1006,224,539,101,1,223,223,8,226,226,224,102,2,223,223,1006,224,554,101,1,223,223,8,677,226,224,102,2,223,223,1005,224,569,1001,223,1,223,1108,677,226,224,1002,223,2,223,1006,224,584,101,1,223,223,1107,677,226,224,1002,223,2,223,1005,224,599,101,1,223,223,107,226,226,224,102,2,223,223,1006,224,614,1001,223,1,223,7,226,677,224,102,2,223,223,1005,224,629,1001,223,1,223,107,677,226,224,1002,223,2,223,1005,224,644,1001,223,1,223,1107,677,677,224,102,2,223,223,1006,224,659,101,1,223,223,1008,226,226,224,1002,223,2,223,1006,224,674,1001,223,1,223,4,223,99,226', ',')
                                 with ordinality as program(code, position)
               ) as program(position, code);

create function read_immediate(jsonb, int4) returns int4 as
$$
    select (($1->'state')->$2)::int4;
$$
language sql immutable;

create function read_position(jsonb, int4) returns int4 as
$$
    select read_immediate($1, read_immediate($1, $2));
$$
language sql immutable;

create function read(jsonb, int4, int4) returns int4 as
$$
    select case when $3 = 0 then read_position($1, $2) else read_immediate($1, $2) end;
$$
language sql immutable;

create function set_immediate(jsonb, int4, int4) returns jsonb as
$$
    select jsonb_set($1, array['state', read_immediate($1, $2)::text], to_jsonb($3));
$$
language sql immutable;

create function process(int4) returns setof int4 as
$$
    with recursive
    stack(iteration, position, program) as
    (
        select     0, 0, jsonb_build_object('state', to_jsonb(array_agg(program.code order by program.position)))
        from       program
        union all
        select     stack.iteration + 1,
                   case when q2.opcode = 1 then stack.position + 4
                        when q2.opcode = 2 then stack.position + 4
                        when q2.opcode = 3 then stack.position + 2
                        when q2.opcode = 4 then stack.position + 2
                        when q2.opcode = 5 then case when read(stack.program, position + 1, (q1.opcode / 100) % 10) != 0 then read(stack.program, position + 2, (q1.opcode / 1000) % 10) else stack.position + 3 end
                        when q2.opcode = 6 then case when read(stack.program, position + 1, (q1.opcode / 100) % 10) = 0 then read(stack.program, position + 2, (q1.opcode / 1000) % 10) else stack.position + 3 end
                        when q2.opcode = 7 then stack.position + 4
                        when q2.opcode = 8 then stack.position + 4
                   end,
                   case when q2.opcode = 1 then set_immediate(stack.program, position + 3, read(stack.program, position + 1, (q1.opcode / 100) % 10) + read(stack.program, position + 2, (q1.opcode / 1000) % 10))
                        when q2.opcode = 2 then set_immediate(stack.program, position + 3, read(stack.program, position + 1, (q1.opcode / 100) % 10) * read(stack.program, position + 2, (q1.opcode / 1000) % 10))
                        when q2.opcode = 3 then set_immediate(stack.program, position + 1, $1)
                        when q2.opcode = 4 then jsonb_set(stack.program, '{output}', to_jsonb(read(stack.program, position + 1, (q1.opcode / 100) % 10)))
                        when q2.opcode = 5 then stack.program
                        when q2.opcode = 6 then stack.program
                        when q2.opcode = 7 then set_immediate(stack.program, position + 3, (read(stack.program, position + 1, (q1.opcode / 100) % 10) < read(stack.program, position + 2, (q1.opcode / 1000) % 10))::int4)
                        when q2.opcode = 8 then set_immediate(stack.program, position + 3, (read(stack.program, position + 1, (q1.opcode / 100) % 10) = read(stack.program, position + 2, (q1.opcode / 1000) % 10))::int4)
                   end
        from       stack,
        lateral    (select read_immediate(stack.program, stack.position)) as q1(opcode),
        lateral    (select q1.opcode % 100) as q2(opcode)
        where      q2.opcode != 99
    )
    select      (stack.program->'output')::int4
    from        stack
    order by    stack.iteration desc
    limit       1;
$$
language sql stable;

select * from process(1);
select * from process(5);

rollback;
