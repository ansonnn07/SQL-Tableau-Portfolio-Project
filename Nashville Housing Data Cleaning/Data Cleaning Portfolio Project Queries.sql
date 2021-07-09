/*

Cleaning Data in SQL Queries

*/


SELECT *
FROM PortfolioProject..NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format by converting them to "Date" type


SELECT SaleDate, CONVERT(Date, SaleDate)
FROM NashvilleHousing


UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

-- If it doesn't UPDATE properly
-- Create a column first before updating
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDateConverted, SaleDate
FROM NashvilleHousing


 --------------------------------------------------------------------------------------------------------------------------

-- Fill in the Missing Property Address data by looking for 
-- their address from the previous records of the same ParcelID
-- but different UniqueID

SELECT *
FROM NashvilleHousing
WHERE ParcelID IN (
	SELECT ParcelID
	FROM NashvilleHousing
	WHERE PropertyAddress IS NULL
	)
ORDER BY ParcelID, SaleDate


SELECT
	a.[UniqueID ],
	a.ParcelID,
	a.PropertyAddress,
	COALESCE(a.PropertyAddress, b.PropertyAddress) AS fixed_address
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] != b.[UniqueID ]
WHERE a.ParcelID IN (
	SELECT ParcelID
	FROM NashvilleHousing
	WHERE PropertyAddress IS NULL
	)
ORDER BY a.ParcelID, a.PropertyAddress


UPDATE a
SET PropertyAddress = COALESCE(a.PropertyAddress,b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL




--------------------------------------------------------------------------------------------------------------------------

-- Splitting Address into Individual Columns (Address, City, State)


SELECT PropertyAddress
FROM NashvilleHousing
--ORDER BY ParcelID

-- Using CHARINDEX to find the index of the comma to use as the split index for SUBSTRING.
-- The '- 1' and '+ 1' are used to exclude the comma.
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address1
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS Address2
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)


ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))


SELECT PropertyAddress, PropertySplitAddress, PropertySplitCity
FROM NashvilleHousing



-- Using another method to split the OwnerAddress column

SELECT OwnerAddress
FROM NashvilleHousing

-- Using PARSENAME which split the name by the period punctuation.
-- REPLACE replaces the commas into periods to be able to use PARSENAME.
-- But due to the syntax of PARSENAME, the order starts from the end of the OwnerAddress,
-- thus the '3, 2, 1' to get the address splits in the correct order.
SELECT
	OwnerAddress
	,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
	,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
	,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
FROM NashvilleHousing



ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)



ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)



SELECT *
FROM NashvilleHousing




--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold AS Vacant" field


SELECT SoldAsVacant, COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


SELECT 
	DISTINCT SoldAsVacant,
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END AS fixed_sold
FROM NashvilleHousing


UPDATE NashvilleHousing
SET SoldAsVacant = 
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END






-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Find duplicate rows

SELECT [UniqueID ], COUNT([UniqueID ])
FROM NashvilleHousing
GROUP BY [UniqueID ]
ORDER BY 2 DESC

WITH RowNumCTE AS (
SELECT
	*,
	ROW_NUMBER() OVER (
		PARTITION BY 
			ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
		ORDER BY
			UniqueID
			) AS row_num
FROM NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE ParcelID IN (
	SELECT ParcelID 
	FROM RowNumCTE
	WHERE row_num != 1
	)
ORDER BY PropertyAddress;


-- Another method
WITH RowCounts AS (
SELECT 
	ParcelID,
	PropertyAddress,
	SalePrice,
	SaleDate,
	LegalReference,
	COUNT(*) AS row_count
FROM NashvilleHousing
GROUP BY 
	ParcelID,
	PropertyAddress,
	SalePrice,
	SaleDate,
	LegalReference
)
SELECT *
FROM NashvilleHousing
WHERE ParcelID IN (
	SELECT ParcelID
	FROM RowCounts
	WHERE row_count != 1
	)
ORDER BY ParcelID




---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns



SELECT *
FROM NashvilleHousing


ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate















-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO


















