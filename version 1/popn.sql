




do $$
declare
	recpt text := 'gaap_sh_clean_3919';
	pop text := 'sh_pop_den_modi_crs4499';
	radii text[] = array['15000','10000','5000','3000','2500','2000','1500','1000', '500'];
	i text;
	sql text;
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
		drop table if exists pop_' || i || ';
		create table pop_' || i || ' as select b.id, sum((intsct.dn*intsct.area)/st_area(b.b'|| i ||')) as den
		from buffers as b left join
          (select b.id, r.dn, st_area(st_intersection(r.geom,b.b'|| i ||')) as area
	         from '|| pop ||' as r, buffers as b
	         where st_intersects(r.geom,  b.b'|| i ||')
	         group by b.id, r.dn, r.geom,  b.b'|| i ||') as intsct
           on b.id=intsct.id
					 group by b.id';
		execute sql;
	end loop;
end;
$$language plpgsql;
