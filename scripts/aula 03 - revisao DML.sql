-- Inserir

insert into funcionario values
('70291549403', 'Ryan', 'Almeida', 'ryanalds@gmail.com', 'Natal-RN', 12000, '2002-12-21', 'M', null, null),
('70291549404', 'Maria', 'Silva', 'maria@gmail.com', 'Natal-RN', 10000, '2002-12-21', 'F', null, null),
('70291549405', 'João', 'Souza', 'joao@gmail.com', 'Natal-RN', 8500, '2002-12-21', 'M', null, null),
('70291549406', 'Ana', 'Costa', 'ana@gmail.com', 'Natal-RN', 9000, '2002-12-21', 'F', null, null),
('70291549407', 'Pedro', 'Almeida', 'pedro@gmail.com', 'Natal-RN', 11000, '2002-12-21', 'M', null, null),
('70291549408', 'Lucas', 'Silva', 'lucas@gmail.com', 'Natal-RN', 5000, '2002-12-21', 'M', null, null),
('70291549409', 'Carla', 'Souza', 'carla@gmail.com', 'Natal-RN', 7000, '2002-12-21', 'F', null, null),
('70291549410', 'Marcos', 'Costa', 'marcos@gmail.com', 'Natal-RN', 6000, '2002-12-21', 'M', null, null);


-- Atualizar

update funcionario
set salario = salario * 1.1
where pnome = 'Lucas' and unome = 'Silva';

-- Remover

-- Remover
-- delete from funcionario
-- where cpf='44455566677'
-- returning cpf, pnome, unome;

