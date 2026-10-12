create table audit.logs (
	id bigint identity(1, 1) primary key,
	user_id int not null,
	procedure_name nvarchar(300) not null,
	executed_at datetime2 not null default getdate(),
	parameters_json nvarchar(max) null,
	client_ip varchar(100) null,
	success bit not null,
	constraint audit_logs_user_id_fk foreign key (user_id)
		references security.users(id)
);

create table audit.login_attempts (
	id int identity(1,1) primary key,
	username nvarchar(200) null,
	email nvarchar(320) null,
	client_ip nvarchar(45) null,
	is_success bit not null,
	failure_reason nvarchar(255) null,
	created_at datetime2 not null default sysutcdatetime()
);
