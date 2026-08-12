drop table if exists funcionarios cascade;
drop table if exists departamentos cascade;


create table funcionarios (
    cpf char(11) primary key,
    pnome varchar(50) not null,
    unome varchar(50),
    email varchar(50) unique,
    endereco varchar(100),
    salario numeric(7,2),
    data_nasc date,
    sexo char(1),
    cpf_surpervisor char(11),
    numero_departamento smallint not null,

    constraint funcionario_salrio_check
    check (salario >= 2000 and salario <= 15000)
);

create table departamentos (
    numero smallint primary key,
    nome varchar(50) not null,
    cpf_gerente char(11)
);

-- Adicionar um novo atributo

alter table departamentos
add column data_ini date;

-- Alterar atributo

alter table departamentos
alter column data_ini set not null;

-- Excluir atributo

alter table departamentos 
drop column data_ini;

--Adicionar restrição padrão

alter table funcionarios
alter column endereco set default 'Macau-RN';

--Excluir um valor DEFAULT

alter table funcionarios
alter column endereco drop default;

-- AAdicionar restrição

alter table funcionarios
add constraint funcionarios_sexo_check
--check (lower(sexo) in ('m', 'f', 'o'));
check (sexo in ('m', 'f', 'o', 'M', 'F', 'O'));

-- Excluir restrição

alter table funcionarios
drop constraint if exists funcionarios_sexo_check;

-- Adicionar restrição FOREING KEY
alter table funcionarios
add  constraint funcionarios_num_dep_fk
foreign key (numero_departamento)
references departamentos(numero)
-- set null, no action, cascade, set default, restrict
on delete no action
on update cascade;