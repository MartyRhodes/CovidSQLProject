/*

Covid-19 Data Exploration from Our World in Data, https://ourworldindata.org/coronavirus

Two Excel datasets, CovidDeathsNew.xlsx and CovidVaccinationsNew.xlsx were created 
from https://github.com/owid/covid-19-data/tree/master/public/data and then imported to SQL tables, 
dbo.CovidDeathsNew and dbo.CovidVaccinationsNew.

Both CovidDeathsNew and CovidVaccinationsNew contain 299,131 records, dated from 2020-01-01 to 2023-03-29.

*/


--DEATHS TABLE EXPLORATION

SELECT * 
FROM CovidOWID1..CovidDeathsNew
ORDER BY continent, location, date
--Many values are NULL for continent.
--Location usually designates a country.


SELECT COUNT(date)
FROM CovidOWID1..CovidDeathsNew
--299,131 records


SELECT  *
FROM CovidOWID1..CovidDeathsNew
ORDER BY location, date



--VACCINATIONS TABLE EXPLORATION

SELECT COUNT(date)
FROM CovidOWID1..CovidVaccinationsNew
--299,131 records


SELECT * 
FROM CovidOWID1..CovidDeathsNew
ORDER BY continent, location, date



--SELECT SPECIFIC DATA ORDERED BY LOCATION AND DATE

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidOWID1..CovidDeathsNew
ORDER BY 1,2



--COVID INFECTION AND DEATH STATISTICS BY COUNTRY

--Which locations (countries) have the highest infection count?

SELECT location, continent, MAX(CAST(total_cases AS INT)) AS TotalInfections
FROM CovidOWID1..CovidDeathsNew
GROUP BY location, continent
ORDER BY TotalInfections DESC
--Several locations are not countries but actually continents or socio-economic levels.
--The country with the highest infection count is the U.S. with 102,697,566 total infections, followed
--by China, India, and France.


--Which locations (countries) have the highest infection rate (adjusted for population size)?

SELECT location, population, MAX(total_cases) AS InfectionCount, MAX(total_cases/population) * 100 
	AS InfectionRate
FROM CovidOWID1..CovidDeathsNew
GROUP BY location, population
ORDER BY InfectionRate DESC
--Cyprus has the highest infection rate, 73.07% of the population. U.S. ranked 68th with 30.36% 
--of the population infected. Adjustment by population size is essential for meaningful interpretation and
--ranking.


--Which locations (countries) have the highest death count?

SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeaths
FROM CovidOWID1..CovidDeathsNew
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeaths DESC
--The highest death count is for the U.S., 1,117,054.


--Which locations (countries) have the highest mortality rate (adjusted for population size)?

SELECT location, population, MAX(CAST(total_deaths AS INT))/population * 100 AS MortalityRate
FROM CovidOWID1..CovidDeathsNew
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY MortalityRate DESC
--These results show a different picture. The highest mortality rate was for Peru, 0.65%,
--followed by Bulgaria, and Bosnia and Herzegovina. The U.S. ranked 19th with a mortality rate of 0.33%.


--What percentage of the U.S. population was infected with Covid, ordered by date?

SELECT location, date, population, total_cases,  (total_cases/population)*100 AS InfectionRate 
From CovidOWID1..CovidDeathsNew
--WHERE location LIKE '%states%' AND location NOT LIKE '%Virgin%'
ORDER BY InfectionRate DESC
--Eliminated Virgin Islands because the population size is so different than the rest of the U.S.
--The cumulative InfectionRate is 30.36% as of 3/29/23.
--The population remains the same for every date, and an individual could be counted multiple times
--in the total_cases. 


--What is the mortality rate of the U.S. ordered by date?

SELECT location, date, total_cases, total_deaths, 
	CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT)*100 AS MortalityRate
FROM CovidOWID1..CovidDeathsNew
WHERE location LIKE '%state%' AND location NOT LIKE '%Virgin%' AND total_cases IS NOT NULL 
	AND total_deaths IS NOT NULL
ORDER BY MortalityRate
--Mortality rates range from 1.09% on 01/13/23 to 6.13% on 05/09/20.



--COVID INFECTION AND DEATH STATISTICS BY CONTINENT

--Order the locations (countries) by population within a continent.

SELECT continent, location,  population
FROM CovidOWID1..CovidDeathsNew
WHERE continent is not null 
GROUP BY continent, location, population
ORDER BY continent, population DESC
--Records reduced to 284,913 when NULL values are eliminated.
--The continent and location appear accurate.


--Which continents have the highest infection count?

SELECT continent, MAX(CAST(total_cases AS INT)) AS TotalInfections
FROM CovidOWID1..CovidDeathsNew
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalInfections DESC
--North America has the highest infection count, 102,697,566; Asia has 99,238,143.


--Which continents have the highest death count?

SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeaths
FROM CovidOWID1..CovidDeathsNew
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeaths DESC
--North America has the highest death count, 1,117,054, followed by South America, 699,917.


--Which continents have the highest mortality rate (adjusted for population)?

SELECT continent, MAX(CAST(total_deaths AS FLOAT)/population * 100) AS MortalityRate
FROM CovidOWID1..CovidDeathsNew
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY MortalityRate DESC
--When the query is adjusted for population, the mortality rate for South America is highest, 0.65%,
--followed by Europe, 0.56%, Asia, 0.45%, North America, 0.33%. Oceania, 0.24%, and Africa, 0.23%.



--VACCCINATION STATISTICS

SELECT *
FROM CovidOWID1..CovidDeathsNew death
JOIN CovidOWID1..CovidVaccinationsNew vac
	ON death.location = vac.location
	AND death.date = vac.date


--New_vaccinations per day by location (country) and date

SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations
FROM CovidOWID1..CovidDeathsNew death
JOIN CovidOWID1..CovidVaccinationsNew vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL
ORDER BY 2,3


--What is the rolling total of vaccinations for each location (country)?

SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY 
	death.location, death.date) AS CumulativeVaccinations
FROM CovidOWID1..CovidDeathsNew death
JOIN CovidOWID1..CovidVaccinationsNew vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
ORDER BY 2,3
--This adds up the new vaccinations for each location. It aggregates until it comes to a new location.
--Used CONVERT instead of CAST.
--Will use this query in a CTE to calculate a vaccination rate (new_vaccinations/population).


--What is the vaccination rate for each location, adjusted for population using various techniques?


--CTE

WITH VacRate (continent, location, date, population, new_vaccinations, PeopleVaccinated)
AS
(
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY 
	death.location, death.date) AS PeopleVaccinated
FROM CovidOWID1..CovidDeathsNew death
JOIN CovidOWID1..CovidVaccinationsNew vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
)
--The columns in the WITH must match with the SELECT.
SELECT *, PeopleVaccinated/Population * 100 AS VaccinationRate
FROM VacRate
ORDER BY location


--Temp Table

DROP TABLE IF EXISTS #VacRate
CREATE TABLE #VacRate
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
PeopleVaccinated numeric
)

INSERT INTO #VacRate
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY 
	death.location, death.date) AS PeopleVaccinated
FROM CovidOWID1..CovidDeathsNew death
JOIN CovidOWID1..CovidVaccinationsNew vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE vac.new_vaccinations IS NOT NULL

SELECT *, PeopleVaccinated/Population * 100 AS VaccinationRate
FROM #VacRate
ORDER BY location, VaccinationRate
--Still getting vaccination rates over 100% after a certain date for some locations.


--View 

CREATE VIEW VacRateView AS
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY 
	death.location, death.date) AS PeopleVaccinated
FROM CovidOWID1..CovidDeathsNew death
JOIN CovidOWID1..CovidVaccinationsNew vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
--There are some definite issues here. New_vaccinations do not account for multiple vaccinations for a person. 
--Also for some countries, such as Australia and Argentina, the cumulative vaccinations do not make sense.
--Two locations, United Arab Emirates and Pitcairn Island reported 105.83% and 100%, respectively, for
--at least one vaccination. For Pitcairn Island, this is the total population of 47 vaccinated. For UAE, 
--a percentage over 100% may be because the population size from 2022 was used, but this data includes
--vaccinations also given in 2023.

SELECT *
FROM VacRateView


--QUERIES USING PEOPLE_VACCINATED INSTEAD OF NEW_CASES

--What is the vaccination rate for each location?

SELECT death.location, death.date, vac.people_vaccinated AS TotalVaccinated,
	death.population AS CountryPopulation, 
	vac.people_vaccinated/death.population * 100 AS PercentVaccinated
FROM CovidOWID1..CovidDeathsNew death
JOIN CovidOWID1..CovidVaccinationsNew vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL AND vac.people_vaccinated IS NOT NULL 
ORDER BY location, PercentVaccinated DESC


--What is the vaccination rate for the U.S.?

SELECT death.location, vac.people_vaccinated AS TotalVaccinated,
	death.population AS CountryPopulation, 
	vac.people_vaccinated/death.population * 100 AS PercentVaccinated
FROM CovidOWID1..CovidDeathsNew death
JOIN CovidOWID1..CovidVaccinationsNew vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL AND vac.people_vaccinated IS NOT NULL AND
	death.location = 'United States'
ORDER BY location, PercentVaccinated DESC
--79.76% of the U.S. population received at least one vaccination for a total of 269,835,963 people
--vaccinated at least once.


