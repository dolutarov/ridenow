create view silver.vw_locations
as
select
	l.id as location_id,
	l.zone_name,
	b.item_name as borough_name,
	s.item_name as service_zone_name,
	l.valid_from,
	l.valid_to
from silver.locations l
	join administrative.items b on b.id = l.borough_item_id
	join administrative.items s on s.id = l.service_zone_item_id
where l.valid_to >= getdate();
