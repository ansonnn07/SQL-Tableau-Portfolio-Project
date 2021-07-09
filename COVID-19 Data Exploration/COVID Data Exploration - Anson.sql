/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- Checking null continents.
-- Something is wrong with the locations, which should be countries,
-- but continents are also found in the location column when continent is null,
-- therefore they are filtered out from here onwards.
SELECT DISTINCT location FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL;

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;


-- Checking number of unique countries in each continent
SELECT
	COALESCE(continent, 'UNKNOWN') AS continent,
	COUNT(DISTINCT location) AS number_of_unique_countries
FROM PortfolioProject..CovidDeaths
-- WHERE continent IS NULL
GROUP BY continent
ORDER BY continent


-- Counting total number of days 
SELECT COUNT(DISTINCT date) 
FROM PortfolioProject..CovidDeaths;


-- SELECT Data that we are going to be starting with
SELECT 
	Location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2;


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract COVID in your country

SELECT 
	Location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%malay%'
and continent IS NOT NULL 
ORDER BY 1,2;


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT 
	Location, 
	date,
	Population,
	total_cases,
	(total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%malay%'
ORDER BY 1,2;


-- Countries with Highest Infection Rate compared to Population

SELECT 
	Location, 
	Population, 
	MAX(total_cases) as HighestInfectionCount,  
	Max((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%malay%'
GROUP BY Location, Population
ORDER BY Location ASC;


-- Countries with Highest Death Count per Population

SELECT Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%malay%'
WHERE continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount desc;


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population

SELECT continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%malay%'
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount desc;


-- GLOBAL NUMBERS

SELECT
	SUM(new_cases) as total_cases, 
	SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int)) / SUM(New_Cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%malay%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2;


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one COVID vaccine
-- The provided data for vaccinations has a lot of null values all over the place,
--  so it is different from the new calculated field of total vaccinations

SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	vac.total_vaccinations,
-- new calculated cumulative total vaccinations
	SUM(CONVERT(INT, vac.new_vaccinations)) 
		OVER (PARTITION BY
				dea.Location
				ORDER BY dea.location, dea.Date) 
		AS total_vaccinations_calc
-- , (total_vaccinations_calc/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE 
	dea.continent IS NOT NULL
	AND vac.new_vaccinations IS NOT NULL
--	AND dea.location LIKE '%malay%'
ORDER BY 2,3;


-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac AS (
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	vac.total_vaccinations,
-- new calculated cumulative total vaccinations
	SUM(CONVERT(INT, vac.new_vaccinations)) 
		OVER (PARTITION BY
				dea.Location
				ORDER BY dea.location, dea.Date) 
		AS total_vaccinations_calc
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE
	dea.continent IS NOT NULL
)
SELECT *, (total_vaccinations_calc/Population)*100 AS PctTotalVaccinations
FROM PopvsVac
-- WHERE New_Vaccinations IS NOT NULL



-- Using Temp Table to combine data for calculation on PARTITION BY in previous query
--  and further exploration

DROP TABLE IF EXISTS #CombinedData
CREATE TABLE #CombinedData (
Continent VARCHAR(255),
Location VARCHAR(255),
Date DATETIME,
Month_of_year DATETIME,
Population NUMERIC,
New_cases NUMERIC,
total_cases NUMERIC,
New_vaccinations NUMERIC,
-- A new calculated cumulative vaccinations
total_vaccinations_calc NUMERIC
)

INSERT INTO #CombinedData
SELECT
	dea.continent,
	dea.location,
	dea.date,
-- new column to truncate the month from the date
--	RIGHT(CONVERT(varchar, dea.date, 3), 5) AS month_of_year,
	DATEFROMPARTS(YEAR(dea.date), MONTH(dea.date), 1) AS month_of_year,
	dea.population,
	dea.new_cases,
	dea.total_cases,
	vac.new_vaccinations,
-- Temp table seems like can only accept a maximum of 9 columns
--	vac.total_vaccinations,
-- new calculated cumulative total vaccinations
	SUM(CONVERT(INT, vac.new_vaccinations)) 
		OVER (PARTITION BY
				dea.Location
				ORDER BY dea.location, dea.Date) 
		AS total_vaccinations_calc
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE 
	dea.continent IS NOT NULL

SELECT *, (total_vaccinations_calc/Population)*100 AS PctTotalVaccinations
FROM #CombinedData
ORDER BY Location, Date;

-- Filtering non-null to make things easier to read
SELECT *, (total_vaccinations_calc/Population)*100 AS PctTotalVaccinations
FROM #CombinedData
WHERE new_vaccinations IS NOT NULL
ORDER BY Location, Date;


-- Show monthly cases by country
SELECT
	combi.Location,
	combi.Month_of_year,
	SUM(combi.New_cases) AS monthly_cases,
	SUM(CAST(dea.new_deaths AS INT)) AS monthly_deaths,
	SUM(combi.New_vaccinations) AS monthly_vaccinations
FROM #CombinedData combi
-- WHERE location LIKE 'malay%'
JOIN PortfolioProject..CovidDeaths dea
	ON combi.Location = dea.location
	AND combi.Date = dea.date
GROUP BY combi.Location, combi.Month_of_year
ORDER BY combi.Location, combi.Month_of_year

-- Create view to store for visualizations.
-- Cannot create view when using temp tables,
--  therefore had to use CTE for this.
CREATE VIEW Combined_Data AS
WITH CombinedData AS (
SELECT
	dea.continent,
	dea.location,
	dea.date,
-- new column to truncate the month from the date
--	RIGHT(CONVERT(varchar, dea.date, 3), 5) AS month_of_year,
	DATEFROMPARTS(YEAR(dea.date), MONTH(dea.date), 1) AS month_of_year,
	dea.population,
	dea.new_cases,
	dea.total_cases,
	dea.new_deaths,
	dea.total_deaths,
	vac.new_vaccinations,
-- new calculated cumulative total vaccinations
	SUM(CONVERT(INT, vac.new_vaccinations)) 
		OVER (PARTITION BY
				dea.Location
				ORDER BY dea.location, dea.Date) 
		AS total_vaccinations_calc
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE 
	dea.continent IS NOT NULL
)
SELECT
	Location,
	month_of_year,
	SUM(New_cases) AS monthly_cases,
	SUM(CAST(new_deaths AS INT)) AS monthly_deaths,
	SUM(CAST(new_vaccinations AS INT)) AS monthly_vaccinations
FROM CombinedData
-- WHERE location LIKE 'malay%'
GROUP BY Location, month_of_year
-- ORDER BY Location, month_of_year


-- Find 7-day rolling average of daily new cases
-- categorized by country, using window functions
CREATE VIEW Rolling_7D_Cases AS
SELECT
	continent,
	location,
	date,
	population,
	new_cases,
	SUM(new_cases) 
		OVER (PARTITION BY location 
			ORDER BY date 
			ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
		AS cases_7d,
	ROUND
	(
		AVG(new_cases) 
		OVER (PARTITION BY location 
			ORDER BY date 
			ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),
		4
	) AS rolling_avg_7d,
	total_cases,
--  a calculated field for total cases to compare with original data
	SUM(new_cases)
		OVER (PARTITION BY location ORDER BY location, date)
		AS total_cases_calc
FROM PortfolioProject..CovidDeaths
WHERE
	continent IS NOT NULL;
--	AND location = 'Malaysia';



-- Creating View for total vaccinations to store data for later visualizations

CREATE VIEW Total_vaccinations AS
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(INT,vac.new_vaccinations)) 
		OVER (PARTITION BY dea.Location
			ORDER BY dea.location, dea.Date)
		AS total_vaccinations_calc
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT * FROM Total_Vaccinations;