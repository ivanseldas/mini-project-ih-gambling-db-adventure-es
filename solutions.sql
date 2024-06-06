-- Query 1;
SELECT DISTINCT Title, FirstName, LastName, DateOfBirth
FROM Customer;

-- Query 2: 
SELECT 
    CustomerGroup,
    COUNT(CustomerGroup) AS Total
FROM
	Customer 
GROUP BY
	CustomerGroup;

-- Query 3:
ALTER TABLE customer 
ADD COLUMN CurrencyCode VARCHAR(3);

-- Disable safe mode for the current session
SET SQL_SAFE_UPDATES = 0;

-- Perform the update
UPDATE customer
LEFT JOIN account a ON a.custid = customer.custid
SET customer.CurrencyCode = a.CurrencyCode;

-- Re-enable safe mode for safety
SET SQL_SAFE_UPDATES = 1;
SELECT * FROM customer;

-- Query 4
SELECT
	Product,
    BetDate,
    SUM(Bet_Amt) AS TotalBet
FROM
	betting
GROUP BY
    BetDate,
    Product
ORDER BY
	BetDate ASC,
    TotalBet DESC;
    
-- Query 5
SELECT
	Product,
    BetDate,
    SUM(Bet_Amt) AS TotalBet
FROM
	betting
WHERE
		(SELECT EXTRACT(month FROM BetDate) >= 11)
    AND 
		(Product = 'Sportsbook')
GROUP BY
    BetDate,
    Product
ORDER BY
	BetDate ASC,
    TotalBet DESC;

-- Query 6: Bet_amount group by CustomerGroup and CurrencyCode from 1-NOV
SELECT
	a.CurrencyCode AS CurrencyCode,
    c.CustomerGroup AS CustomerGroup,
    SUM(b.Bet_Amt) AS TotalBet
FROM
	betting b
LEFT JOIN 
	account a ON b.AccountNo = a.AccountNo
LEFT JOIN
	customer c ON a.CustId = c.CustId
WHERE
	(SELECT EXTRACT(month FROM BetDate) >= 11)
GROUP BY
    CurrencyCode,
    CustomerGroup
ORDER BY
	TotalBet DESC;

-- Query 7:  Nuestro equipo VIP ha pedido ver un informe de todos los jugadores independientemente de si han hecho algo en el marco de tiempo completo o no.
 -- En nuestro ejemplo, es posible que no todos los jugadores hayan estado activos. Por favor, escribe una consulta SQL que muestre a todos los jugadores 
 -- Título, Nombre y Apellido y un resumen de su cantidad de apuesta para el período completo de noviembre.
SELECT
	c.Title AS Title,
    c.FirstName AS FirstName,
    c.LastName AS LastName,
    b.BetDate AS BetDate,
    SUM(b.Bet_Amt) AS BetSum,
    SUM(b.BetCount) AS BetCount
FROM
	customer c
LEFT JOIN
	account a ON c.CustId = a.CustId
LEFT JOIN
	betting b ON a.AccountNo = b.AccountNo
WHERE
	(SELECT EXTRACT(month FROM BetDate) = 11)
GROUP BY
	BetDate,
	Title,
    FirstName,
    LastName
ORDER BY
	BetDate,
	Title,
    FirstName,
    LastName;

-- Query 8: Nuestros equipos de marketing y CRM quieren medir el número de jugadores que juegan más de un producto. ¿Puedes por favor escribir 2 consultas?
-- Query 8.1: muestre el número de productos por jugador
WITH PlayerProduct AS (
	SELECT 
		AccountNo,
		CASE 
        WHEN Product IS NULL THEN 'N/A' 
        ELSE Product 
		END AS Product
	FROM betting
	GROUP BY AccountNo, Product
	ORDER BY AccountNo
)
SELECT AccountNo, COUNT(Product) AS ProductCount
FROM PlayerProduct
GROUP BY AccountNo
ORDER BY AccountNo;

-- Query 8.2:muestre jugadores que juegan tanto en Sportsbook como en Vegas
WITH PlayerProduct AS (
	SELECT 
		AccountNo,
		CASE 
			WHEN Product IS NULL THEN 'N/A' 
			ELSE Product 
		END AS Product
	FROM betting
)
SELECT AccountNo
FROM PlayerProduct
WHERE Product IN  ('Vegas', 'Sportsbook')
GROUP BY AccountNo
HAVING COUNT(DISTINCT Product) = 2;

-- QUERY 9:Ahora nuestro equipo de CRM quiere ver a los jugadores que solo juegan un producto, por favor escribe código SQL 
-- que muestre a los jugadores que solo juegan en sportsbook, usa bet_amt > 0 como la clave. 
-- Muestra cada jugador y la suma de sus apuestas para dicho producto.
WITH PlayerProduct AS (
	SELECT 
		a.CustId AS CustId,
        c.Title AS Title,
        c.FirstName AS FirstName,
        c.LastName AS LastName,
		CASE 
			WHEN b.Product IS NULL THEN 'N/A' 
			ELSE b.Product 
		END AS Product,
        b.Bet_Amt AS Bet_Amt
	FROM betting b
    INNER JOIN account a ON b.AccountNo = a.AccountNo
    INNER JOIN customer c ON a.CustId = c.CustId
)
SELECT 
	CustId, 
	Title, 
    FirstName, 
    LastName,
    SUM(Bet_Amt) AS Bet_Sum
FROM PlayerProduct
WHERE (Product = 'Sportsbook') AND (Bet_Amt > 0)
GROUP BY CustId, Title, FirstName, LastName;

-- QUERY 10: Show favourite game of each player by total amount bet
WITH PlayerProduct AS (
	SELECT 
		a.CustId AS CustId,
        c.Title AS Title,
        c.FirstName AS FirstName,
        c.LastName AS LastName,
		CASE 
			WHEN b.Product IS NULL THEN 'N/A' 
			ELSE b.Product 
		END AS Product,
        b.Bet_Amt AS Bet_Amt
	FROM betting b
    INNER JOIN account a ON b.AccountNo = a.AccountNo
    INNER JOIN customer c ON a.CustId = c.CustId
), 
FavouriteGame AS (
SELECT
	CustId, 
	Title, 
    FirstName, 
    LastName,
    Product,
    SUM(Bet_Amt) AS Bet_Sum
FROM PlayerProduct
GROUP BY Product, CustID, Title, FirstName, LastName
ORDER BY CustId
)
SELECT DISTINCT
	CustId, 
	Title, 
    FirstName, 
    LastName,
    FIRST_VALUE(Bet_Sum) OVER (PARTITION BY CustID) AS Bet_Sum,
    FIRST_VALUE(Product) OVER (PARTITION BY CustID) AS Favourite
FROM FavouriteGame;