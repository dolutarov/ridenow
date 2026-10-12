create table security.users (
	id int identity(1, 1) primary key,
	username nvarchar(200) null,					-- for local login
	email nvarchar(320) not null unique,			-- required for Google login
	password_hash varbinary(512) null,			  -- null for Google-only users
	password_salt varbinary(256) null,
	display_name nvarchar(200) null,
	is_active bit not null default 1,
	created_at datetime2 not null default sysutcdatetime(),
	valid_from datetime2 generated always as row start not null,
	valid_to datetime2 generated always as row end not null,
	period for system_time (valid_from, valid_to)
)
with (system_versioning = on (
		history_table = security.users_history,
		data_consistency_check = on
	)
);

create table security.roles (
	id int identity(1, 1) primary key,
	role_code varchar(100) not null unique,
	role_name nvarchar(200) not null,
	valid_from datetime2 generated always as row start not null,
	valid_to datetime2 generated always as row end not null,
	period for system_time (valid_from, valid_to)
)
with (system_versioning = on (
		history_table = security.roles_history,
		data_consistency_check = on
	)
);

create table security.user_roles (
	user_id int not null,
	role_id int not null,
	valid_from datetime2 generated always as row start not null,
	valid_to datetime2 generated always as row end not null,
	period for system_time (valid_from, valid_to),
	constraint security_user_roles_pk primary key (user_id, role_id),
	constraint security_user_roles_user_id_fk foreign key (user_id) references security.users(id),
	constraint security_user_roles_role_id_fk foreign key (role_id) references security.roles(id)
)
with (system_versioning = on (
		history_table = security.user_roles_history,
		data_consistency_check = on
	)
);
