-- Lista 02 - Views, Indexes e Triggers

-- Questao 01 
CREATE OR REPLACE VIEW v_staff_performance AS
SELECT
    s.staff_id,
    concat_ws(' ', s.first_name, s.last_name) AS full_name,
    concat_ws(', ', ci.city, co.country) AS store_address,
    COALESCE(r.rentals, 0) AS total_rentals,
    COALESCE(p.total_revenue, 0)::numeric(10, 2) AS total_revenue
FROM staff AS s
JOIN store AS st ON st.store_id = s.store_id
JOIN address AS a ON a.address_id = st.address_id
JOIN city AS ci ON ci.city_id = a.city_id
JOIN country AS co ON co.country_id = ci.country_id
LEFT JOIN (
    SELECT staff_id, COUNT(*) AS rentals
    FROM rental
    GROUP BY staff_id
) AS r ON r.staff_id = s.staff_id
LEFT JOIN (
    SELECT staff_id, SUM(amount) AS total_revenue
    FROM payment
    GROUP BY staff_id
) AS p ON p.staff_id = s.staff_id;

-- Validacao
SELECT * FROM v_staff_performance ORDER BY staff_id;


-- Questao 02 
CREATE MATERIALIZED VIEW mv_category_total_sales AS
SELECT
    c.name AS category_name,
    COALESCE(SUM(p.amount), 0)::numeric(12, 2) AS total_sales
FROM category AS c
LEFT JOIN film_category AS fc ON fc.category_id = c.category_id
LEFT JOIN inventory AS i ON i.film_id = fc.film_id
LEFT JOIN rental AS r ON r.inventory_id = i.inventory_id
LEFT JOIN payment AS p ON p.rental_id = r.rental_id
GROUP BY c.category_id, c.name;

CREATE UNIQUE INDEX ux_mv_category_total_sales_category
    ON mv_category_total_sales (category_name);

-- Validacao
SELECT * FROM mv_category_total_sales ORDER BY category_name;


-- Questao 03 
CREATE INDEX idx_rental_open_rentals
    ON rental (rental_date)
    WHERE return_date IS NULL;

EXPLAIN (ANALYZE, BUFFERS)
SELECT rental_id, rental_date, inventory_id, customer_id, staff_id
FROM rental
WHERE return_date IS NULL;


-- Questao 04 
CREATE INDEX idx_film_description_fts
    ON film USING GIN (to_tsvector('english', description));

EXPLAIN (ANALYZE, BUFFERS)
SELECT film_id, title, description
FROM film
WHERE to_tsvector('english', description)
      @@ to_tsquery('english', 'documentary | drama');


-- Questao 05 
CREATE INDEX idx_payment_customer_date_desc
    ON payment (customer_id, payment_date DESC);

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM payment
WHERE customer_id = 1
ORDER BY payment_date DESC;


-- Questao 06 
CREATE INDEX idx_customer_email_lower
    ON customer (lower(email));

EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, first_name, last_name, email
FROM customer
WHERE lower(email) = lower('MARY.SMITH@sakilacustomer.org');


-- Questao 07 
CREATE OR REPLACE FUNCTION check_rental_return_date()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.return_date IS NOT NULL AND NEW.return_date < NEW.rental_date THEN
        RAISE EXCEPTION 'A data de devolucao nao pode ser anterior a data da locacao.';
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_check_rental_return_date
BEFORE INSERT OR UPDATE OF rental_date, return_date ON rental
FOR EACH ROW
EXECUTE FUNCTION check_rental_return_date();

BEGIN;

INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
VALUES (
    CURRENT_TIMESTAMP,
    (SELECT inventory_id FROM inventory ORDER BY inventory_id LIMIT 1),
    (SELECT customer_id FROM customer ORDER BY customer_id LIMIT 1),
    NULL,
    (SELECT staff_id FROM staff ORDER BY staff_id LIMIT 1)
);

DO $$
DECLARE
    v_inventory_id integer;
    v_customer_id integer;
    v_staff_id integer;
BEGIN
    SELECT inventory_id INTO v_inventory_id FROM inventory ORDER BY inventory_id LIMIT 1;
    SELECT customer_id INTO v_customer_id FROM customer ORDER BY customer_id LIMIT 1;
    SELECT staff_id INTO v_staff_id FROM staff ORDER BY staff_id LIMIT 1;

    BEGIN
        INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
        VALUES (
            CURRENT_TIMESTAMP,
            v_inventory_id,
            v_customer_id,
            CURRENT_TIMESTAMP - INTERVAL '1 day',
            v_staff_id
        );
        RAISE EXCEPTION 'O teste falhou: a data invalida foi aceita.';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'Teste de falha passou: a data invalida foi rejeitada.';
        WHEN raise_exception THEN
            IF SQLERRM = 'O teste falhou: a data invalida foi aceita.' THEN
                RAISE;
            END IF;
            RAISE NOTICE 'Teste de falha passou: %', SQLERRM;
    END;
END;
$$;

ROLLBACK;


-- Questao 08
CREATE TABLE IF NOT EXISTS film_cost_audit (
    film_id integer NOT NULL,
    old_cost numeric(5, 2),
    new_cost numeric(5, 2),
    changed_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION audit_film_replacement_cost()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO film_cost_audit (film_id, old_cost, new_cost)
    VALUES (OLD.film_id, OLD.replacement_cost, NEW.replacement_cost);
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_audit_film_replacement_cost
AFTER UPDATE OF replacement_cost ON film
FOR EACH ROW
WHEN (OLD.replacement_cost IS DISTINCT FROM NEW.replacement_cost)
EXECUTE FUNCTION audit_film_replacement_cost();


-- Questao 09 
CREATE OR REPLACE FUNCTION prevent_language_delete_when_used()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM film AS f
        WHERE f.language_id = OLD.language_id
           OR f.original_language_id = OLD.language_id
    ) THEN
        RAISE EXCEPTION 'Nao e possivel excluir o idioma "%": existem filmes vinculados.', OLD.name;
    END IF;
    RETURN OLD;
END;
$$;

CREATE OR REPLACE TRIGGER trg_prevent_language_delete_when_used
BEFORE DELETE ON language
FOR EACH ROW
EXECUTE FUNCTION prevent_language_delete_when_used();


-- Questao 10 
CREATE TABLE IF NOT EXISTS customer_rental_stats (
    customer_id integer PRIMARY KEY REFERENCES customer (customer_id),
    total_rentals integer NOT NULL DEFAULT 0
);

-- Inicializa e sincroniza a tabela com os dados existentes.
INSERT INTO customer_rental_stats (customer_id, total_rentals)
SELECT c.customer_id, COUNT(r.rental_id)::integer
FROM customer AS c
LEFT JOIN rental AS r ON r.customer_id = c.customer_id
GROUP BY c.customer_id
ON CONFLICT (customer_id) DO UPDATE
SET total_rentals = EXCLUDED.total_rentals;

CREATE OR REPLACE FUNCTION increment_customer_rental_stats()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO customer_rental_stats (customer_id, total_rentals)
    VALUES (NEW.customer_id, 1)
    ON CONFLICT (customer_id) DO UPDATE
    SET total_rentals = customer_rental_stats.total_rentals + 1;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_increment_customer_rental_stats
AFTER INSERT ON rental
FOR EACH ROW
EXECUTE FUNCTION increment_customer_rental_stats();

-- Validacao
SELECT customer_id, total_rentals
FROM customer_rental_stats
ORDER BY customer_id;
