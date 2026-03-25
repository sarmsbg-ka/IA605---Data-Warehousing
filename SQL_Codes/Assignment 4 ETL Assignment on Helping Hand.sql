-- Q3 Create Fundraisers from EMPLOYEE (source: HHSourceDB)

INSERT INTO Fundraisers
    (FundraiserID, FundraiserName, FundraiserSex,
     FRLocationID, FRLocationName, FRLocationAddress, FundRaiserType)
SELECT  emp.Eid, emp.Ename, emp.Esex,
        loc.Lid, loc.Lname, loc.Laddress,
        'Employee'
FROM   [HHSourceDB.accdb].LOCATION  loc,
       [HHSourceDB.accdb].EMPLOYEE emp
WHERE  loc.Lid = emp.Lid;

-- Append Fundraisers from VOLUNTEER (source: HHSourceDB)

INSERT INTO Fundraisers
    (FundraiserID, FundraiserName, FundraiserSex,
     FRLocationID, FRLocationName, FRLocationAddress, FundRaiserType)
SELECT  vol.Vid, vol.Vname, vol.Vsex,
        loc.Lid, loc.Lname, loc.Laddress,
        'Volunteer'
FROM   [HHSourceDB.accdb].LOCATION  loc,
       [HHSourceDB.accdb].VOLUNTEER vol
WHERE  loc.Lid = vol.Lid;

-- Q1 Load Donors staging table from INDIVIDUAL (source: HHSourceDB)

INSERT INTO Donors (DonorName, DonorSex, DonorID)
SELECT Iname, Isex, Iid
FROM   [HHSourceDB].INDIVIDUAL;

-- Q2 Load Donors dimension in HHDW from staging Donors
INSERT INTO HHDW.Donors (DonorKey, DonorName, DonorSex, DonorID)
SELECT DonorKey, DonorName, DonorSex, DonorID
FROM   Donors;

-- Q4 Load Fundraisers dimension in HHDW from staging Fundraisers

INSERT INTO HHDW.Fundraisers
    (FundraisersKey, FRLocationID, FundraiserID,
     FundraiserName, FundraiserSex,
     FRLocationAddress, FRLocationName, FundraiserType)
SELECT FundraisersKey, FRLocationID, FundraiserID,
       FundraiserName, FundraiserSex,
       FRLocationAddress, FRLocationName, FundraiserType
FROM   Fundraisers;
