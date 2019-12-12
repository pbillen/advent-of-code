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
                   from      regexp_split_to_table('3,26,1001,26,-4,26,3,27,1002,27,2,27,1,27,26,27,4,27,1001,28,-1,28,1005,28,6,99,0,0,5', ',')
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

create function process(int4[]) returns int4 as
$$
    with recursive
    stack(iteration, input_position, program_position, program) as
    (
        select     0, 1, 0, jsonb_build_object('state', to_jsonb(array_agg(program.code order by program.position)))
        from       program
        union all
        select     stack.iteration + 1,
                   case when q2.opcode = 3 then stack.input_position + 1
                        else                    stack.input_position
                   end,
                   case when q2.opcode = 1 then stack.program_position + 4
                        when q2.opcode = 2 then stack.program_position + 4
                        when q2.opcode = 3 then stack.program_position + 2
                        when q2.opcode = 4 then stack.program_position + 2
                        when q2.opcode = 5 then case when read(stack.program, program_position + 1, (q1.opcode / 100) % 10) != 0 then read(stack.program, program_position + 2, (q1.opcode / 1000) % 10) else stack.program_position + 3 end
                        when q2.opcode = 6 then case when read(stack.program, program_position + 1, (q1.opcode / 100) % 10) = 0 then read(stack.program, program_position + 2, (q1.opcode / 1000) % 10) else stack.program_position + 3 end
                        when q2.opcode = 7 then stack.program_position + 4
                        when q2.opcode = 8 then stack.program_position + 4
                   end,
                   case when q2.opcode = 1 then set_immediate(stack.program, program_position + 3, read(stack.program, program_position + 1, (q1.opcode / 100) % 10) + read(stack.program, program_position + 2, (q1.opcode / 1000) % 10))
                        when q2.opcode = 2 then set_immediate(stack.program, program_position + 3, read(stack.program, program_position + 1, (q1.opcode / 100) % 10) * read(stack.program, program_position + 2, (q1.opcode / 1000) % 10))
                        when q2.opcode = 3 then set_immediate(stack.program, program_position + 1, $1[input_position])
                        when q2.opcode = 4 then jsonb_set(stack.program, '{output}', to_jsonb(read(stack.program, program_position + 1, (q1.opcode / 100) % 10)))
                        when q2.opcode = 5 then stack.program
                        when q2.opcode = 6 then stack.program
                        when q2.opcode = 7 then set_immediate(stack.program, program_position + 3, (read(stack.program, program_position + 1, (q1.opcode / 100) % 10) < read(stack.program, program_position + 2, (q1.opcode / 1000) % 10))::int4)
                        when q2.opcode = 8 then set_immediate(stack.program, program_position + 3, (read(stack.program, program_position + 1, (q1.opcode / 100) % 10) = read(stack.program, program_position + 2, (q1.opcode / 1000) % 10))::int4)
                   end
        from       stack,
        lateral    (select read_immediate(stack.program, stack.program_position)) as q1(opcode),
        lateral    (select q1.opcode % 100) as q2(opcode)
        where      q2.opcode != 99
    )
    select      (stack.program->'output')::int4
    from        stack
    order by    stack.iteration desc
    limit       1;
$$
language sql stable;

select    max(process(array[e] || array[process(array[d] || array[process(array[c] || array[process(array[b] || array[process(array[a] || array[0])])])])]))
from      generate_series(0, 4) as a,
          generate_series(0, 4) as b,
          generate_series(0, 4) as c,
          generate_series(0, 4) as d,
          generate_series(0, 4) as e
where     a != b and a != c and a != d and a != e and
                     b != c and b != d and b != e and
                                c != d and c != e and
                                           d != e;

select    max(process(array[e] || array[process(array[d] || array[process(array[c] || array[process(array[b] || array[process(array[a] || array[0])])])])]))
from      generate_series(5, 9) as a,
          generate_series(5, 9) as b,
          generate_series(5, 9) as c,
          generate_series(5, 9) as d,
          generate_series(5, 9) as e
where     a != b and a != c and a != d and a != e and
                     b != c and b != d and b != e and
                                c != d and c != e and
                                           d != e;

rollback;
