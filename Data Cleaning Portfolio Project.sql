/*

Cleaning Data in SQL Queries
by Shawn Pokharel

*/
USE [PortfolioProject ]



Select *
From [PortfolioProject ]..NashvilleHousing$


--------------------------------------------------------------------------------------------------------------------------


-- Standardize Date Format

-- The SaleDate column includes the time in minutes at the end, which serves no purpose.
-- We will be getting rid of the time by converting the SaleDate column from DateTime format to Date format.


Select SaleDateConverted, Convert(Date,SaleDate)
From [PortfolioProject ]..NashvilleHousing$

-- Updating the column to convert the data type so it'll look cleaner. From "2013-10-09 00:00:00.000" Format to "2013-10-09"

Update NashvilleHousing$
Set SaleDate = CONVERT(Date,SaleDate)

ALTER Table NashvilleHousing$
Add SaleDateConverted Date;

Update NashvilleHousing$
Set SaleDateConverted = CONVERT(Date,SaleDate)





 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

Select *
From [PortfolioProject ]..NashvilleHousing$
--Where PropertyAddress is NUll
order by ParcelID


-- There are many instances in the dataset where property address is null. However, Property Address that have values corresponded to a specific ParcelID.
-- For example, if the Parcel ID is "007 00 0 151.00" the Property Address will be"1821  FOX CHASE DR, GOODLETTSVILLE".
-- So in the case of blank property addresses we can look to the ParcelID to determine which PropertyAddress needs to be populated.


-- Performing a self join where the ParcelID is the same but containing a different UniqueID.
-- The self join will allow us to look at records where the ParcelID is the same for both values but one PropertyAddress is null.
-- ISNULL() will check if the a.PropertyAdress is null. And if it IS NULL it will populate the record with b.PropertyAddress.


Select a.ParcelID, a.PropertyAddress, b.ParcelID,b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From [PortfolioProject ]..NashvilleHousing$ a
Join [PortfolioProject ]..NashvilleHousing$ b
	on a.ParcelID=b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


-- THis will update the alias a with PropertyAddress values from b.

Update a
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From [PortfolioProject ]..NashvilleHousing$ a
Join [PortfolioProject ]..NashvilleHousing$ b
	on a.ParcelID=b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


-- Currently the PropertyAddress column lists the Address followed by a Comma then the City

Select PropertyAddress
From [PortfolioProject ]..NashvilleHousing$ 
--Where PropertyAddress is NUll
--order by ParcelID


-- Substring allows us to choose which column to work with as well as which position to search for a comma.
-- CharIndex will search for a Comma in Property Address, but we must add a -1 because the Substring includes the comma. The -1 subtracts 1 from the total length of the Substring.
-- The second Substring function will show us the rest of the string past the comma and finish at the length of the entire string.

Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address
, SUBSTRING(PropertyAddress,  CHARINDEX(',', PropertyAddress) + 1, Len(PropertyAddress)) as City
From [PortfolioProject ]..NashvilleHousing$ 


-- Alters the database to add the Split Address and Split City, making it so much more usable.

ALTER Table NashvilleHousing$
Add PropertySplitAddress nvarchar(255);

Update NashvilleHousing$
Set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER Table NashvilleHousing$
Add PropertySplitCity nvarchar(255);

Update NashvilleHousing$
Set PropertySplitCity = SUBSTRING(PropertyAddress,  CHARINDEX(',', PropertyAddress) + 1, Len(PropertyAddress))



Select *
From [PortfolioProject ]..NashvilleHousing$


-- This time we will be splitting up the Owner's Address. The Owner Address includes Address, City, and State in one string.
-- We will be using a different method using the PARSENAME() in order to seperate the string.
-- Normally ParseName searches for a period so we have to define that we are looking for a comma.
-- ParseName oddly enough goes backwords so instead of Address being position 1 we have State instead.
-- City is position 2 and Address is position 3.


Select
PARSENAME(Replace(OwnerAddress, ',', '.'), 3) as Address,
PARSENAME(Replace(OwnerAddress, ',', '.'), 2) as City,
PARSENAME(Replace(OwnerAddress, ',', '.'), 1) as State
From [PortfolioProject ]..NashvilleHousing$


-- Here we are altering the Database to add these columns with the split address, city, and state.

ALTER Table NashvilleHousing$
Add OwnerSplitAddress nvarchar(255);

Update NashvilleHousing$
Set OwnerSplitAddress = PARSENAME(Replace(OwnerAddress, ',', '.'), 3)


ALTER Table NashvilleHousing$
Add OwnerSplitCity nvarchar(255);

Update NashvilleHousing$
Set OwnerSplitCity = PARSENAME(Replace(OwnerAddress, ',', '.'), 2)


ALTER Table NashvilleHousing$
Add OwnerSplitState nvarchar(255);

Update NashvilleHousing$
Set OwnerSplitState = PARSENAME(Replace(OwnerAddress, ',', '.'), 1)


Select *
From [PortfolioProject ]..NashvilleHousing$


--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

-- SoldAsVacant currently has four types: Y, N, Yes, and No.
-- We want to include Y and N with Yes and No because they are the same values and shouldnt be recorded differently.
-- So a CASE statement is in order that will select the column SoldAsVacant and if the record is Y then the value is Yes. With N the value will be No

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From [PortfolioProject ]..NashvilleHousing$
Group by SoldAsVacant
Order by 2


Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' Then 'Yes'
	   When SoldAsVacant = 'N' Then 'No'
	   Else SoldAsVacant
	   END
From [PortfolioProject ]..NashvilleHousing$


-- We will update the table to include Y an N values to their correspoding Yes and No Values.

Update NashvilleHousing$
Set SoldAsVacant = CASE When SoldAsVacant = 'Y' Then 'Yes'
	   When SoldAsVacant = 'N' Then 'No'
	   Else SoldAsVacant
	   END
From [PortfolioProject ]..NashvilleHousing$


-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates


-- For the purpose of this example we will assume their is no UniqueID. If ParcelID, PropertyAddress, SalePrice, SaleDate, and LegalReference and the same values on two different records we will assume their is a duplicate.
-- ROW_Number() numbers all the rows sequentially so we can Partition the dataset over the columns we want to check on.
-- RowNumCTE is a temporary table of the Select statement we created. This allows us to query off of the table we created.
-- We can see there are 104 duplicates that we want to delete.

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From PortfolioProject.dbo.NashvilleHousing$
--order by ParcelID
)
--DELETE
Select *
From RowNumCTE
Where row_num > 1
--Order by PropertyAddress



Select *
From PortfolioProject.dbo.NashvilleHousing$



---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

Select *
From PortfolioProject.dbo.NashvilleHousing$



-- Earlier we split the PropertyAddress and OwnerAddress as well as converted SaleDate.
-- So we will want to drop these tables and for the heck of it we will also drop TaxDistrict.
-- This makes our data so much more cleaner and easier to work with.

ALTER TABLE PortfolioProject.dbo.NashvilleHousing$
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