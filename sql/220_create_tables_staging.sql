create table staging.taxi_zone_lookup (
	LocationID int,
	Borough nvarchar(100),
	Zone nvarchar(200),
	service_zone nvarchar(100)
);


create table staging.YellowTripData (
	id bigint not null identity(1,1) primary key,
	VendorID int,
	tpep_pickup_datetime datetime2,
	tpep_dropoff_datetime datetime2,
	passenger_count bigint,
	trip_distance float,
	RatecodeID bigint,
	store_and_fwd_flag nvarchar(10),
	PULocationID int,
	DOLocationID int,
	payment_type bigint,
	fare_amount float,
	extra float,
	mta_tax float,
	tip_amount float,
	tolls_amount float,
	improvement_surcharge float,
	total_amount float,
	congestion_surcharge float,
	Airport_fee float,
	file_name nvarchar(1000),
	uploading_process varchar(100),
	file_upload_timestamp datetime2 not null default getdate(),
	ingesting_errors nvarchar(max)
);


create table staging.YellowTripData_transform_log (
	id bigint not null primary key,
	ingestion_time datetime2 not null default getdate(),
	ingesting_procedure varchar(100) not null,
	is_success bit not null default 0,
	failure_reason nvarchar(max)
);