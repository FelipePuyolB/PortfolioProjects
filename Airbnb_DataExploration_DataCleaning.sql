

SELECT *
FROM Portfolio_Airbnb..DataAirbnb

SELECT *
FROM Portfolio_Airbnb..ReviewsAirbnb




-- We join two different files to be able to work with more data with the join functions (We could not use the Union function since the operator
-- must have an equal number of expressions in their target lists). Then we choose the apartments that have a price greater than 
-- 300 USD and that are not within Manhattan, and we end up ordering them by neighborhood

SELECT DataAirbnb.Host_Id, DataAirbnb.Host_Since, DataAirbnb.Name, Neighbourhood, Property_Type, Room_Type, Beds, Price, Number_Of_Reviews
FROM Portfolio_Airbnb.dbo.DataAirbnb
Inner Join Portfolio_Airbnb.dbo.ReviewsAirbnb
	ON DataAirbnb.Host_Id = ReviewsAirbnb.Host_Id
	and DataAirbnb.Host_Since = ReviewsAirbnb.Host_Since
	and DataAirbnb.Name = ReviewsAirbnb.Name
	WHERE Price > 300
	and Neighbourhood <> 'Manhattan'
	ORDER BY Neighbourhood





-- We create a CTE that counts the number of apartments and calculates the percentage of apartments that
-- have a price greater than 300 compared to the total number of apartments from the same neighborhood and separates them by neighborhood

WITH CTE_Airbnb AS (
  SELECT 
    Neighbourhood, 
    COUNT(*) as Total_Apartments, 
    SUM(CASE WHEN price > 300 THEN 1 ELSE 0 END) as Deluxe_Apartments
  FROM Portfolio_Airbnb..DataAirbnb
  GROUP BY Neighbourhood
)
SELECT 
  Neighbourhood, 
  Total_Apartments, 
  Deluxe_Apartments, 
  ROUND(100.0 * Deluxe_Apartments / Total_Apartments, 2) as Percentage_Expensive
FROM CTE_Airbnb




-- We create a Temp Table to manage the information easily, at the same time we will show the data that the Host Id's are divisible by two, 
-- the type of property is a loft and they have more than two beds. If the temp table already exists, the code will ignore it and create another one.

DROP Table if exists #Airbnb_apts
Create Table #Airbnb_apts
(
Host_Id numeric,
Host_Since datetime,
Name nvarchar(255),
Neighbourhood nvarchar(255),
Property_Type nvarchar(255),
Room_Type nvarchar(255),
Zipcode numeric,
Beds numeric,
Price numeric
)

INSERT INTO #Airbnb_apts
SELECT *
FROM Portfolio_Airbnb..DataAirbnb

SELECT *
FROM #Airbnb_apts
WHERE Host_Id % 2 = 0 AND Property_Type = 'Loft' AND Beds > 2;




-- We separate the departments into 3 groups. Those with a price less than 100, those with a price 
-- between 100 and 300, and those that are over 300. We create a count for each group. 
WITH department_pricing AS (
    SELECT 
        CASE 
            WHEN price < 100 THEN 'Less than 100 USD' 
            WHEN price BETWEEN 100 AND 300 THEN 'Between 100 USD and 300 USD' 
            ELSE 'Over 300 USD' 
        END AS Price_Range
    FROM Portfolio_Airbnb..DataAirbnb
)

SELECT Price_Range, COUNT(*) as Number_of_Apartments
FROM department_pricing
GROUP BY Price_Range




-- Now we create a view with the 100 most expensive apartments including the number of beds, the type of apartment and its neighborhood

CREATE VIEW Most_Expensive_Apartments AS 
SELECT 
  Neighbourhood,
  Property_Type,
  Beds, 
  Price
FROM Portfolio_Airbnb..DataAirbnb
ORDER BY Price DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

SELECT * FROM Most_Expensive_Apartments




-- Now we will delete all the duplicates from the file DataAirbnb

WITH DeleteDupCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY Host_Id,
				 Name,
				 Property_Type,
				 Room_Type,
				 ZipCode,
				 Beds,
				 Price
				 ORDER BY
					Host_Id
					) row_num

FROM Portfolio_Airbnb..DataAirbnb
)
DELETE
FROM DeleteDupCTE
Where row_num > 1




-- Now we will delete all the unused columns from the file ReviewsAirbnb

SELECT *
FROM Portfolio_Airbnb..ReviewsAirbnb

ALTER TABLE Portfolio_Airbnb..ReviewsAirbnb
DROP COLUMN Number_of_Records































