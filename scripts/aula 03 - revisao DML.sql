-- Inserir

insert into funcionarios values
('70291549403', 'Ryan', 'Almeida', 'ryanalds@gmail.com', 'Natal-RN', 12000, '2002-12-21', 'M', null, null),
('11111111111', 'Ana', 'Almeida', 'ana@gmail.com', 'Natal-RN', 12000, '2002-12-21', 'F', null, null),
('22222222222', 'Kleber', 'Almeida', 'kleber@gmail.com', 'Natal-RN', 12000, '2002-12-21', 'M', null, null);

-- Atualizar

update funcionarios 
set unome= 'Silva'
where cpf= '70291549403'
returning cpf, pnome, unome;

-- Remover

delete from funcionarios
where cpf= '70291549403'
returning cpf, pnome, unome;