/**********item categories**********/
-- Boroughs
insert into administrative.item_categories (category_code, category_name)
values
	('borough', N'Borough'),
	('service_zone', N'Service Zone'),
	('rate_code', N'Rate Code'),
	('payment_type', N'Payment Type')
;



/**********items**********/
--borough
declare @borough_cat_id int = (
	select id from administrative.item_categories where category_code = 'borough'
);

insert into administrative.items (category_id, item_code, item_name)
values
	(@borough_cat_id, 'EWR', N'EWR'),
	(@borough_cat_id, 'Queens', N'Queens'),
	(@borough_cat_id, 'Bronx', N'Bronx'),
	(@borough_cat_id, 'Manhattan', N'Manhattan'),
	(@borough_cat_id, 'Staten Island', N'Staten Island'),
	(@borough_cat_id, 'Brooklyn', N'Brooklyn'),
	(@borough_cat_id, 'Unknown', N'Unknown'),
	(@borough_cat_id, 'N/A', N'N/A')
;


--service_zone
declare @service_zone_cat_id int = (
	select id from administrative.item_categories where category_code = 'service_zone'
);

insert into administrative.items (category_id, item_code, item_name)
values
	(@service_zone_cat_id, 'EWR', N'EWR'),
	(@service_zone_cat_id, 'Boro Zone', N'Boro Zone'),
	(@service_zone_cat_id, 'Yellow Zone', N'Yellow Zone'),
	(@service_zone_cat_id, 'Airports', N'Airports'),
	(@service_zone_cat_id, 'N/A', N'N/A')
;


--rate_code
declare @rate_code_cat_id int = (
	select id from administrative.item_categories where category_code = 'rate_code'
);

insert into administrative.items (category_id, item_code, item_name)
values
	(@rate_code_cat_id, '1',  N'Standard rate'),
	(@rate_code_cat_id, '2',  N'JFK'),
	(@rate_code_cat_id, '3',  N'Newark'),
	(@rate_code_cat_id, '4',  N'Nassau or Westchester'),
	(@rate_code_cat_id, '5',  N'Negotiated fare'),
	(@rate_code_cat_id, '6',  N'Group ride'),
	(@rate_code_cat_id, '99', N'Null/unknown')
;


--payment_type
declare @payment_type_cat_id int = (
	select id from administrative.item_categories where category_code = 'payment_type'
);

insert into administrative.items (category_id, item_code, item_name)
values
	(@payment_type_cat_id, '0', N'Flex Fare trip'),
	(@payment_type_cat_id, '1', N'Credit card'),
	(@payment_type_cat_id, '2', N'Cash'),
	(@payment_type_cat_id, '3', N'No charge'),
	(@payment_type_cat_id, '4', N'Dispute'),
	(@payment_type_cat_id, '5', N'Unknown'),
	(@payment_type_cat_id, '6', N'Voided trip')
;
