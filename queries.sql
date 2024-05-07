------ Section B ------
-- Create function that defines a transformation
-- The function FormatCurrency takes a numeric value as input and returns a string formatted as currency
CREATE OR REPLACE FUNCTION FormatCurrency (amount NUMERIC)
RETURNS VARCHAR
LANGUAGE PLPGSQL
AS $$
BEGIN
  RETURN '$' || TO_CHAR(amount, 'FM999G999G999G990D00');
END;
$$;

-- run the following two blocks of code for manual demonstration
--INSERT INTO Top_Profitable_Movies (film_id, film_title, total_revenue)
--SELECT film_id, film_title, total_revenue
--FROM Movie_Revenue_Details
--ORDER BY total_revenue DESC
--LIMIT 10;

--SELECT film_id, film_title, FormatCurrency (total_revenue) AS formatted_total_revenue
--FROM Top_Profitable_Movies;


------ Section C ------
--Create detailed table
--input the field names and the data types for each field
CREATE TABLE Movie_Revenue_Details (
    film_id                    INT,
    film_title                 VARCHAR (200), 
    total_rentals              INT,
    total_revenue              DECIMAL (10,2),
    average_revenue_per_rental DECIMAL (10,2)
) ;
-- run the following code to display blank table
-- SELECT * FROM Movie_Revenue_Details

-- Create summary table
CREATE TABLE Top_Profitable_Movies (
    film_id       INT,
    film_title    VARCHAR (200),
    total_revenue DECIMAL
) ;
-- run the following code to display blank table
-- SELECT * FROM Top_Profitable_Movies


------ Section D ------
-- specify table and columns in order in which data will be inserted
INSERT INTO Movie_Revenue_Details (film_id, film_title, total_rentals,
total_revenue, average_revenue_per_rental)
-- gather data from tables
-- calculate total rentals, revenue, and average revenue per rental for each film
SELECT
    f. film_id,
    f. title AS film_title,
    COUNT (r.rental_id) AS total_rentals,
    SUM (p.amount) AS total_revenue,
    ROUND (AVG (p. amount) ,2) AS average_revenue_per_rental
FROM film f
-- join the film, inventory, rental, and payment tables to access data
JOIN inventory i ON f. film_id = i. film_id
JOIN rental r ON i. inventory_id = r.inventory_id
JOIN payment p ON r. rental_id = p.rental_id
-- aggregate data by film_id and title
GROUP BY f.film_id, f.title
-- sort results by total revenue in descending order to see most profitable films at top
ORDER BY total_revenue DESC;

-- run the following code to view populated detailed table
-- SELECT * FROM Movie_Revenue_Details


------ Section E ------
-- create trigger function
CREATE OR REPLACE FUNCTION update_summary_table()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    -- clear the summary table to remove old data
    TRUNCATE TABLE Top_Profitable_Movies;
    -- insert new data into table
    INSERT INTO Top_Profitable_Movies (film_id, film_title, total_revenue)
    SELECT film_id, film_title, total _revenue
    FROM Movie_Revenue_Details
    ORDER BY total_revenue DESC
    LIMIT 10;
    -- return new row for row-level triggers
    RETURN NEW;
END;
$$;
-- create trigger
CREATE TRIGGER refresh_summary_after_update
-- set to activate after an insert or update operation on details table
AFTER INSERT OR UPDATE ON Movie_Revenue_Details
-- set trigger to fire for each row
FOR EACH ROW
-- call update summary function
EXECUTE FUNCTION update_summary_table();


------ Section F ------
-- create procedure to refresh the movie revenue reports
CREATE OR REPLACE PROCEDURE refresh_movie_revenue_reports()
LANGUAGE PLPGSQL
AS $$
BEGIN
    TRUNCATE TABLE Movie_Revenue_Details; -- clear data from details & summary table
    TRUNCATE TABLE Top_Profitable_Movies;
    -- Insert fresh data from the necessary relational tables
    INSERT INTO Movie_Revenue_Details (film_id, film_title, total_rentals, total_revenue, average_revenue_per_rental)
    SELECT
        f. film_id,
        f.title As film_title,
        COUNT (r.rental_id) AS total_rentals,
        SUM (p.amount) AS total_revenue,
        ROUND (AVG (p.amount),2) AS average_revenue_per_rental
    FROM film f
    JOIN inventory i ON f.film_id = i.f1lm_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY f. film_id, f.title
    ORDER BY SUM(p.amount) DESC;
    --insert fresh data into the summary table
    INSERT INTO Top_Profitable_Movies (film_id, film_title, total_revenue)
    SELECT film_id, film_title, total_revenue
    FROM Movie_Revenue_Details
    ORDER BY total_revenue DESC
    LIMIT 10;
END;
$$;