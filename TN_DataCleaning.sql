-- First we will start to sort and clean the data, for the next step when we study the data. The results will be more effective and accurate.

SELECT *
FROM Portfolio_Housing..TN_Housing
-------------------------------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format, dates include days, months, and years. We will remove the hours, minutes, etc.

SELECT SaleDateConverted, CONVERT(Date, SaleDate) as Sale_Date
FROM Portfolio_Housing..TN_Housing

ALTER TABLE TN_Housing
ADD SaleDateConverted Date;

UPDATE TN_Housing 
SET SaleDateConverted = CONVERT(Date, SaleDate)

-------------------------------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data, We are going to make a self join so we can populate de PropertyAddress that have the same ParcelID but his 
-- value in the PropertyAddress it's null.

SELECT PropertyAddress
FROM Portfolio_Housing..TN_Housing

SELECT selfjoina.ParcelID, selfjoina.PropertyAddress, selfjoinb.ParcelID, selfjoinb.PropertyAddress, ISNULL(selfjoina.PropertyAddress, selfjoinb.PropertyAddress) 
FROM Portfolio_Housing..TN_Housing selfjoina
JOIN Portfolio_Housing..TN_Housing selfjoinb
	ON selfjoina.ParcelID = selfjoinb.ParcelID
	AND selfjoina.[UniqueID] <> selfjoinb.[UniqueID]
WHERE selfjoina.PropertyAddress is null


UPDATE selfjoina
SET PropertyAddress = ISNULL(selfjoina.PropertyAddress, selfjoinb.PropertyAddress)
FROM Portfolio_Housing..TN_Housing selfjoina
JOIN Portfolio_Housing..TN_Housing selfjoinb
	ON selfjoina.ParcelID = selfjoinb.ParcelID
	AND selfjoina.[UniqueID] <> selfjoinb.[UniqueID]
WHERE selfjoina.PropertyAddress is null


-------------------------------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address Into Individual Columns (Address, City, State).
-- The first method that we will use to separate the address into individual columns will be with the use of substrings.

SELECT PropertyAddress
FROM Portfolio_Housing..TN_Housing

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as Address
FROM Portfolio_Housing..TN_Housing



ALTER TABLE TN_Housing
ADD PropertySplitAddress Nvarchar(255);

UPDATE TN_Housing 
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)



ALTER TABLE TN_Housing
ADD PropertySplitCity Nvarchar(255);

UPDATE TN_Housing 
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))



-- The second method that we use to separate the address into individual columns will be with the use of the function PARSENAME

SELECT OwnerAddress
FROM Portfolio_Housing..TN_Housing

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',','.') , 3 )
, PARSENAME(REPLACE(OwnerAddress, ',','.') , 2 )
, PARSENAME(REPLACE(OwnerAddress, ',','.') , 1 )
FROM Portfolio_Housing..TN_Housing


ALTER TABLE TN_Housing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE TN_Housing 
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.') , 3 )



ALTER TABLE TN_Housing
ADD OwnerSplitCity Nvarchar(255);

UPDATE TN_Housing 
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.') , 2 )



ALTER TABLE TN_Housing
ADD OwnerSplitState Nvarchar(255);

UPDATE TN_Housing 
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.') , 1 )



-------------------------------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No In "Sold as Vacant" field
-- 

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Portfolio_Housing..TN_Housing
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM Portfolio_Housing..TN_Housing


UPDATE TN_Housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END 



-------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH CTE_RDup AS(
SELECT *,
     ROW_NUMBER() OVER (
	 PARTITION BY ParcelID,
	              PropertyAddress,
				  SalePrice,
				  SaleDate,
				  LegalReference
				  ORDER BY
				    UniqueID
					) row_dup

FROM Portfolio_Housing..TN_Housing
)
DELETE
FROM CTE_RDup
WHERE row_dup > 1



-------------------------------------------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns


Select * 
From Portfolio_Housing..TN_Housing

ALTER TABLE Portfolio_Housing..TN_Housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate





-------------------------------------------------------------------------------------------------------------------------------------------------

-- Calculate the profit percentage compared to the total value and the sale price, then we classify how many percentages were positive and how many were negative

WITH Profit_Percentage AS (
     SELECT (SalePrice - TotalValue) AS Profit, ((SalePrice - TotalValue)/(SalePrice)) * 100 AS Profit_Percentage
     FROM Portfolio_Housing..TN_Housing
)
SELECT 
  SUM(CASE WHEN Profit_Percentage > 0 THEN 1 ELSE 0 END) as Positive_Profit_Percentage,
  SUM(CASE WHEN Profit_Percentage < 0 THEN 1 ELSE 0 END) as Negative_Profit_Percentage
FROM Profit_Percentage





