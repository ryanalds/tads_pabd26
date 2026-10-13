-- Q1:

CREATE MATERIALIZED VIEW mv_driver_season_summary AS
SELECT
    r.year,
    d.id AS driver_id,
    d.name AS driver_name,
    COUNT(*) AS total_races,
    COUNT(CASE WHEN rd.position_number = 1 THEN 1 END) AS wins,
    COUNT(CASE WHEN rd.position_number <= 3 THEN 1 END) AS podiums,
    COUNT(CASE WHEN rd.race_reason_retired IS NOT NULL THEN 1 END) AS dnfs,
    COALESCE(SUM(rd.race_points), 0)::numeric(10, 2) AS total_points
FROM race_data AS rd
JOIN race AS r ON r.id = rd.race_id
JOIN driver AS d ON d.id = rd.driver_id
WHERE rd.type = 'RACE_RESULT'
GROUP BY r.year, d.id, d.name;

-- teste:
SELECT year, driver_id, driver_name, total_races, wins, podiums, dnfs, total_points
FROM mv_driver_season_summary
WHERE driver_id = 'ayrton-senna'
ORDER BY year DESC
LIMIT 10;

-- Q2:

CREATE OR REPLACE FUNCTION audit_season_driver_points()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.points IS DISTINCT FROM NEW.points THEN
        INSERT INTO points_adjustment_audit (year, driver_id, old_points, new_points)
        VALUES (OLD.year, OLD.driver_id, OLD.points, NEW.points);
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_audit_season_driver_points
AFTER UPDATE OF points ON season_driver_standing
FOR EACH ROW
EXECUTE FUNCTION audit_season_driver_points();



-- Q3:
