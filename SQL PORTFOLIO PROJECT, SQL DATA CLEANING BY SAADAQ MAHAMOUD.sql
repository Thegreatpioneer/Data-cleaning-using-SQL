create database housingproject  /*Created this database, I then got my messy data that am going to clean and put it
on excel, I then changed the file format from whatever it was (microsoft excel workbook I think) to a CSV
format and then used a flat file to import it into SQL*/

--STEP 1
--The data is really messy and it also has over 56,000 rows and I need to organise what steps I will take.
--The first step that I will take is cleaning the data using SQL queries.
select * from housingproject.dbo.[HouseData]
--I am using this select * statement to see what exactly am dealing with
-------------------------------------------------------------------------------
--STEP 2
--Fixing the data format
--The date has a date time format, so am going to convert it to just date to make it more precise and cleaner
Select SaleDate, CONVERT(Date,SaleDate)
From housingproject.dbo.[HouseData]

Update housingproject.dbo.[HouseData]
SET SaleDate = CONVERT(Date,SaleDate)
--Now the data type on date has been changed to a yyyy/mm/dd format rather than yyyy/mm/dd and time
 --------------------------------------------------------------------------------------------------------------------------
--STEP 3
-- Populating the Property Address data
Select PropertyAddress
From housingproject.dbo.[HouseData]
Where PropertyAddress is null --there are 29 rows of null values where the address is null

Select *
From housingproject.dbo.[HouseData]
order by ParcelID /*If I look through the data the parcel IDs are identical it means they
are sent to the same address, for example this address: 832  STONE HEDGE CT, OLD HICKORY*/
--My goal is now to match the identical parcel ID with the address 

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From  housingproject.dbo.[HouseData] a
JOIN  housingproject.dbo.[HouseData] b
	on a.ParcelID = b.ParcelID /*what this does is joining the table with itself HOWEVER only when the parcel IDS match and where
	the unique ID are different*/
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null /*This condition allows me to find out objects where the parcel IDS are the same
however for one of the parcel ID there is an address whereas for the other parcel ID (despite being sent to the same address its
null) it is null, there is no address within it. So it shows me the result for that column*/ 

Update a -- the definition of a and b was defined last paragraph  
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)-- Where there are nulls, replace it with the column of address
From  housingproject.dbo.[HouseData] a
JOIN  housingproject.dbo.[HouseData] b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ] -- this paragraph is about now replacing the nulls with what the address should actually be.
Where a.PropertyAddress is null 
--If I go back to the previous paragraph and try to execute the query the table will come up as blank as the nulls have been replaced.
--------------------------------------------------------------------------------------------------------------------------
--STEP 4
-- Separating Address into Individual Columns (Address, City, State)
Select PropertyAddress
From housingproject.dbo.[HouseData] --The delimiters are the columns as it can be seen in this query, my goal is to separate them into different columns wherever the commas are

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address --This first line looks through the address until it finds a comma, then it stops and returns a query of that address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address-- This 2nd line then removes the comma and creates a new address column, separting the city from the address
From  housingproject.dbo.[HouseData] --this paragraph is just preparation for the next, I will copy and paste and edit what is needed to alter the table below.

ALTER TABLE [HouseData]
Add PropertySplitAddress Nvarchar(255); --This adds the table of the address
Update [HouseData]
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) --This updates the table of the address

ALTER TABLE [HouseData]
Add PropertySplitCity Nvarchar(255); --This adds the table of the city
Update [HouseData]
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) --This updates the table of the address
--I only did address and city not state, am going to switch the method because this isn't something am really familiar with.
Select *
From housingproject.dbo.[HouseData] --On the far right side of the table I can now see the city and address split, this is more useful for data related things
--The above queries was doing the separation of the columns the hard way which am not familiar with, now am going to start again below and do it the easy way
Select OwnerAddress
From [HouseData]

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3) --owner split address
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2) --owner split city
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1) --owner split state
From housingproject.dbo.[HouseData]-- the column order is in a opposite format, 1 2 3, I need to keep that in mind
--this query above is just preparation for the next part, I will copy and paste where the stuff needs to go

ALTER TABLE [HouseData] 
Add OwnerSplitAddress Nvarchar(255);--added a address column
Update [HouseData]
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)-- Updated it now

ALTER TABLE [HouseData]
Add OwnerSplitCity Nvarchar(255);--added a city column
Update [HouseData]
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)--updated it

ALTER TABLE [HouseData]
Add OwnerSplitState Nvarchar(255);--added a state column
Update [HouseData]
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)--updated it
--------------------------------------------------------------------------------------------------------------------------
--STEP 5
-- Change 1 and 0 to Yes and No in "Sold as Vacant" field

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From housingproject.dbo.[HouseData]
Group by SoldAsVacant
order by 2 --the soldasvacant is in a binary format, 1 for yes, 0 for no, my goal is to change this.

--Ran into a problem, so I had to alter the column value as shown below
alter table housingproject.dbo.Housedata
alter column SoldAsVacant nvarchar(50) --it was previously 'bit', it didnt let my data change from a int to a text. I concluded that the data type was the problem

Select SoldAsVacant
, CASE When SoldAsVacant = '1' THEN 'Yes'
	   When SoldAsVacant = '0' THEN 'No'
	   ELSE SoldAsVacant
	   END
From housingproject.dbo.[HouseData] --This is just preparation before I actually update the data, its good habit for me to double check if my query is working as it should.


Update [HouseData]
SET SoldAsVacant = CASE When SoldAsVacant = '1' THEN 'Yes'
	   When SoldAsVacant = '0' THEN 'No'
	   ELSE SoldAsVacant
	   END
-----------------------------------------------------------------------------------------------------------------------------------------------------------
--STEP 6
-- Delete Unused Columns
Select *
From housingproject.dbo.[HouseData]

ALTER TABLE housingproject.dbo.[HouseData]
DROP COLUMN PropertySplitCity, PropertySplitAddress --dropping the 2 colummns that I do not need anymore.
