create table administrative.item_categories (
	id int identity(1, 1) primary key,
	category_code varchar(100) not null,
	category_name nvarchar(100) not null,
	parent_category_id int,
	category_description nvarchar(max),
	valid_from datetime2 generated always as row start not null,
	valid_to datetime2 generated always as row end not null,
	period for system_time (valid_from, valid_to),
	constraint administrative_item_categories_category_code_uq unique (category_code),
	constraint administrative_item_categories_parent_category_id_fk foreign key (parent_category_id)
				references administrative.item_categories(id)
)
with (system_versioning = on (
		history_table = administrative.item_categories_history,
		data_consistency_check = on
	)
);


create table administrative.items (
	id int identity(1, 1) primary key,
	category_id int not null,
	item_code varchar(200) not null,
	item_name nvarchar(200) not null,
	parent_item_id int,
	item_description nvarchar(max),
	valid_from datetime2 generated always as row start not null,
	valid_to datetime2 generated always as row end not null,
	period for system_time (valid_from, valid_to),
	constraint administrative_items_category_id_item_code_uq unique (category_id, item_code),
	constraint administrative_items_category_id_fk foreign key (category_id)
				references administrative.item_categories(id),
	constraint administrative_items_parent_item_id_fk foreign key (parent_item_id)
				references administrative.items(id)
)
with (system_versioning = on (
		history_table = administrative.items_history,
		data_consistency_check = on
	)
);

