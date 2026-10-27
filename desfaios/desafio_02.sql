-- Questão 1
BEGIN;

INSERT INTO customer (store_id, first_name, last_name, address_id)
VALUES (1, 'Ryan', 'Almeida', 1);

INSERT INTO customer (store_id, first_name, last_name, address_id)
VALUES (1, NULL, 'Souza', 1);

ROLLBACK;

'O cliente não existe, o ROLLBACK desfaz todas as alterações da transação.'

-- Questão 2

BEGIN;

INSERT INTO inventory (film_id, store_id)
SELECT film_id, 1
FROM film
ORDER BY film_id
LIMIT 1;

SAVEPOINT estoque_atualizado;

INSERT INTO inventory (film_id, store_id)
VALUES (32767, 1);

ROLLBACK TO SAVEPOINT estoque_atualizado;

INSERT INTO inventory (film_id, store_id)
SELECT film_id, 1
FROM film
ORDER BY film_id DESC
LIMIT 1;

COMMIT;

'Após o COMMIT, os dois registros validos permanecem, o registro inválido foi desfeito até o SAVEPOINT.' 