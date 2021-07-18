-- Cleaning data in SQL queries

select * from dbo.NashVilleHousing

-- Standardize SaleDate format

select SaleDate,SaleDateConverted
from dbo.NashVilleHousing

ALTER TABLE NashVilleHousing
ADD SaleDateConverted Date;

Update NashVilleHousing
set SaleDateConverted = CONVERT(date,SaleDate)


-- Populate Property Address data where it's null 

select * from dbo.NashVilleHousing
where PropertyAddress is null
order by ParcelID

select a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
from dbo.NashVilleHousing a Join dbo.NashVilleHousing b
	on a.ParcelID = b.ParcelID and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

update a
set PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
from dbo.NashVilleHousing a Join dbo.NashVilleHousing b
	on a.ParcelID = b.ParcelID and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null


-- Breaking out Address into specific columns (Address, City, State)

select PropertyAddress from dbo.NashVilleHousing

select SUBSTRING(PropertyAddress, 1,CHARINDEX(',',PropertyAddress)),CHARINDEX(',',PropertyAddress)
from dbo.NashVilleHousing


-- To get rid of ','

select SUBSTRING(PropertyAddress, 1,CHARINDEX(',',PropertyAddress) -1 ) as PropertyAddress2,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress) +1 ,LEN(PropertyAddress)) as PropertyCity
from dbo.NashVilleHousing

ALTER TABLE NashVilleHousing
ADD PropertyAddress2 nvarchar(256),
	PropertyCity nvarchar(256);

Update NashVilleHousing
set PropertyAddress2 = SUBSTRING(PropertyAddress, 1,CHARINDEX(',',PropertyAddress) -1 ),
	PropertyCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress) +1 ,LEN(PropertyAddress));


select OwnerAddress 
from dbo.NashVilleHousing

select PARSENAME(REPLACE(OwnerAddress,',','.'),3) as Address, 
PARSENAME(REPLACE(OwnerAddress,',','.'),2) as City,
PARSENAME(REPLACE(OwnerAddress,',','.'),1) as State
from dbo.NashVilleHousing

ALTER TABLE NashVilleHousing
ADD OwnerAddress2 nvarchar(256),
	OwnerCity nvarchar(256),
	OwnerState nvarchar(256);

Update NashVilleHousing
set OwnerAddress2 = PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	OwnerCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	OwnerState = PARSENAME(REPLACE(OwnerAddress,',','.'),1);

select * 
from dbo.NashVilleHousing


-- Changing Y and N to Yes and No in SoldAsVacant field

select distinct SoldAsVacant, count(SoldAsVacant)
from dbo.NashVilleHousing
Group By SoldAsVacant
Order by 2

select SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
from dbo.NashVilleHousing
where SoldAsVacant in ('Y','N')

Update dbo.NashVilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END


-- Remove Duplicates 

SELECT * INTO CloneNashVilleHousing FROM NashVilleHousing;

WITH RonNumCTE AS (
select *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,PropertyAddress,SaleDate,SalePrice,LegalReference
	ORDER BY UniqueID
	) row_num

from dbo.NashVilleHousing
--ORDER BY ParcelID
)

select * from RonNumCTE
where row_num > 1  

DELETE FROM RonNumCTE
where row_num > 1 


-- Delete Unused Columns

select * 
from dbo.NashVilleHousing

ALTER TABLE dbo.NashVilleHousing
DROP COLUMN OwnerAddress,TaxDistrict,PropertyAddress

ALTER TABLE dbo.NashVilleHousing
DROP COLUMN SaleDate
