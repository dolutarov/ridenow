create table config.configurations (
	id int identity(1, 1) primary key,
	configuration_name varchar(200) not null,
	configuration_display_name nvarchar(200) not null,
	parent_configuration_id int,
	configuration_description nvarchar(max),
	valid_from datetime2 generated always as row start not null,
	valid_to datetime2 generated always as row end not null,
	period for system_time (valid_from, valid_to),
	constraint config_configurations_configuration_code_uq unique (configuration_name),
	constraint config_configurations_parent_configuration_id_fk foreign key (parent_configuration_id)
				references config.configurations(id)
)
with (system_versioning = on (
		history_table = config.configurations_history,
		data_consistency_check = on
	)
);


create table config.configuration_items (
	id int identity(1, 1) primary key,
	configuration_id int not null,
	item_name varchar(200) not null,
	display_name nvarchar(200) null,
	parent_item_id int,
	item_description nvarchar(max),
	valid_from datetime2 generated always as row start not null,
	valid_to datetime2 generated always as row end not null,
	period for system_time (valid_from, valid_to),
	constraint config_configuration_id_item_code_uq unique (configuration_id, item_name),
	constraint config_configuration_id_fk foreign key (configuration_id)
				references config.configurations(id),
	constraint config_parent_item_id_fk foreign key (parent_item_id)
				references config.configuration_items(id)
)
with (system_versioning = on (
		history_table = config.configuration_items_history,
		data_consistency_check = on
	)
);