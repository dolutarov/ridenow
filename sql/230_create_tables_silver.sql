create table silver.vendors (
	id int identity(1,1) primary key,
	vendor_name nvarchar(200) not null,
	valid_from datetime2 generated always as row start not null,
	valid_to datetime2 generated always as row end not null,
	period for system_time (valid_from, valid_to)
)
with (system_versioning = on (
	history_table = silver.vendors_history,
	data_consistency_check = on
));

create table silver.locations (
	id int identity(1,1) primary key,
	zone_name nvarchar(200) not null,
	borough_item_id int not null,
	service_zone_item_id int not null,
	valid_from datetime2 generated always as row start not null,
	valid_to datetime2 generated always as row end not null,
	period for system_time (valid_from, valid_to),
	constraint fk_silver_locations_borough_item_id foreign key (borough_item_id)
		references administrative.items(id),
	constraint fk_silver_locations_service_zone_item_id foreign key (service_zone_item_id)
		references administrative.items(id)
)
with (system_versioning = on (
	history_table = silver.locations_history,
	data_consistency_check = on
));


create table silver.YellowTrips (
	id bigint identity(1,1) primary key,
	vendor_item_id int not null,
	pickup_datetime datetime2 not null,
	dropoff_datetime datetime2 not null,
	passenger_count int,
	trip_distance float,
	ratecode_item_id int,
	store_and_fwd_flag nvarchar(10),
	pickup_location_id int,
	dropoff_location_id int,
	payment_type int,
	fare_amount float,
	extra float,
	mta_tax float,
	tip_amount float,
	tolls_amount float,
	improvement_surcharge float,
	total_amount float,
	congestion_surcharge float,
	airport_fee float,
	file_name nvarchar(1000),
	uploading_process nvarchar(100),
	valid_from datetime2 generated always as row start not null,
	valid_to datetime2 generated always as row end not null,
	period for system_time (valid_from, valid_to),
	constraint fk_silver_YellowTrips_vendor_item_id foreign key (vendor_item_id)
		references silver.vendors(id),
	constraint fk_silver_YellowTrips_ratecode_item_id foreign key (ratecode_item_id)
		references administrative.items(id),
	constraint fk_silver_YellowTrips_pickup_location_id foreign key (pickup_location_id)
		references silver.locations(id),
	constraint fk_silver_YellowTrips_dropoff_location_id foreign key (dropoff_location_id)
		references silver.locations(id)
)
with (system_versioning = on (
	history_table = silver.YellowTrips_history,
	data_consistency_check = on
));
