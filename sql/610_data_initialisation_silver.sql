SET IDENTITY_INSERT silver.vendors ON;

insert into silver.vendors (id, vendor_name)
values
	(1, N' Creative Mobile Technologies, LLC'),
	(2, N'Curb Mobility, LLC'),
	(6, N'Myle Technologies Inc'),
	(7, N'Helix')
;

SET IDENTITY_INSERT silver.vendors OFF;