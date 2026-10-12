create or alter procedure silver.merge_locations
as
begin
	set nocount on;

	set IDENTITY_INSERT silver.locations ON;

	with src as (
		select
			cast(s.LocationID as int) as id,
			s.Zone as zone_name,
			b.id as borough_item_id,
			sz.id as service_zone_item_id
		from staging.taxi_zone_lookup s
			join administrative.items b on b.item_name = s.Borough
						and b.category_id = (
								select id from administrative.item_categories
								where category_code = 'borough'
						)
			join administrative.items sz on sz.item_name = s.service_zone
						and sz.category_id = (
								select id from administrative.item_categories
								where category_code = 'service_zone'
						)
	)
	merge silver.locations as tgt
	using src as src
		on tgt.id = src.id
	when matched and (
			tgt.zone_name <> src.zone_name or
			tgt.borough_item_id <> src.borough_item_id or
			tgt.service_zone_item_id <> src.service_zone_item_id
		)
		then update set
			tgt.zone_name = src.zone_name,
			tgt.borough_item_id = src.borough_item_id,
			tgt.service_zone_item_id = src.service_zone_item_id

	when not matched by target
		then insert (id, zone_name, borough_item_id, service_zone_item_id)
		values (src.id, src.zone_name, src.borough_item_id, src.service_zone_item_id);


	set IDENTITY_INSERT silver.locations OFF;

end;
go



create or alter procedure silver.insert_YellowTrips
as
begin
	set nocount on;

	begin try
		begin tran;

		if object_id('tempdb..#resolved') is not null drop table #resolved;

		with todo as (
			select s.*
			from staging.YellowTripData s
			left join staging.YellowTripData_transform_log l
				on l.id = s.id
			where l.id is null
			   or l.is_success = 0
		)

			select
				t.id as staging_id,
				v.id as vendor_item_id,
				t.tpep_pickup_datetime as pickup_datetime,
				t.tpep_dropoff_datetime as dropoff_datetime,
				t.passenger_count,
				t.trip_distance,
				r.id as ratecode_item_id,
				t.store_and_fwd_flag,
				pl.id as pickup_location_id,
				dl.id as dropoff_location_id,
				p.id as payment_type_item_id,
				t.fare_amount,
				t.extra,
				t.mta_tax,
				t.tip_amount,
				t.tolls_amount,
				t.improvement_surcharge,
				t.total_amount,
				t.congestion_surcharge,
				t.Airport_fee as airport_fee,
				t.file_name,
				t.uploading_process
			into #resolved
			from todo t
			join silver.vendors v
				on v.id = t.VendorID
			join administrative.items r
				on r.item_code = cast(t.RatecodeID as varchar(10))
			   and r.category_id = (
					select id from administrative.item_categories
					where category_code = 'rate_code'
			   )
			join administrative.items p
				on p.item_code = cast(t.payment_type as varchar(10))
			   and p.category_id = (
					select id from administrative.item_categories
					where category_code = 'payment_type'
			   )
			join silver.locations pl
				on pl.id = t.PULocationID
			join silver.locations dl
				on dl.id = t.DOLocationID


		insert into silver.YellowTrips (
			vendor_item_id,
			pickup_datetime,
			dropoff_datetime,
			passenger_count,
			trip_distance,
			ratecode_item_id,
			store_and_fwd_flag,
			pickup_location_id,
			dropoff_location_id,
			payment_type,
			fare_amount,
			extra,
			mta_tax,
			tip_amount,
			tolls_amount,
			improvement_surcharge,
			total_amount,
			congestion_surcharge,
			airport_fee,
			file_name,
			uploading_process
		)
		select
			vendor_item_id,
			pickup_datetime,
			dropoff_datetime,
			passenger_count,
			trip_distance,
			ratecode_item_id,
			store_and_fwd_flag,
			pickup_location_id,
			dropoff_location_id,
			payment_type_item_id,
			fare_amount,
			extra,
			mta_tax,
			tip_amount,
			tolls_amount,
			improvement_surcharge,
			total_amount,
			congestion_surcharge,
			airport_fee,
			file_name,
			uploading_process
		from #resolved;

		merge staging.YellowTripData_transform_log as logt
		using #resolved as src
			on logt.id = src.staging_id
		when matched then
			update set
				logt.is_success = 1,
				logt.failure_reason = null,
				logt.ingesting_procedure = 'silver.insert_YellowTrips',
				logt.ingestion_time = sysdatetime()
		when not matched then
			insert (id, is_success, failure_reason, ingesting_procedure, ingestion_time)
			values (src.staging_id, 1, null, 'silver.insert_YellowTrips', sysdatetime());

		if object_id('tempdb..#resolved') is not null drop table #resolved;

		commit tran;
	end try

	begin catch
		rollback tran;

		declare @msg nvarchar(max) = error_message();

		insert into staging.YellowTripData_transform_log (
			id, is_success, failure_reason, ingesting_procedure
		)
		select staging_id, 0, @msg, 'silver.insert_YellowTrips'
		from #resolved;

		throw;
	end catch
end;
go
