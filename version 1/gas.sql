begin
	drop table if exists buffers;

	--Make buffers
	sql := 'create table buffers as	select ';
	foreach i in array radii
	loop
		sql := sql || 'st_buffer(r.geom, ' || i || ') as b' || i || ',';
	end loop;
	sql := sql || 'r.id from ' || recpt || ' as r';
	execute sql;

	--Perform intersections
	foreach i in array radii
	loop
		raise notice '%', i;
		execute 'create index buf_indx_' || i || ' on buffers' || ' using gist (b' || i || ')';

		sql := '
		drop table if exists poi_gas_station_s' || i || ';
		create table poi_gas_station_s' || i || ' as
		select b.id, coalesce(count(d.geom), 0) as number
		from buffers as b left join '||poi||' as d
		on st_contains(b.b'|| i ||', d.geom)
		group by b.id';
		execute sql;
	end loop;
end;
$$language plpgsql;
