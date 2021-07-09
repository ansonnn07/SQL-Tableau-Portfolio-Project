-- 1. 

SELECT 
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS INT)) AS total_deaths,
	SUM(CAST(new_deaths AS INT)) / SUM(New_Cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
ORDER BY 1,2

-- Just a double check based off the data provided
-- numbers are extremely close so we will keep them - The Second includes "International"  Location

--SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(New_Cases)*100 AS DeathPercentage
--FROM PortfolioProject..CovidDeaths
--WHERE location = 'World'
--ORDER BY 1,2


-- 2. 

-- We take these out AS they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

SELECT location, SUM(CAST(new_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL 
	AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC


-- 3.

SELECT 
	Location,
	Population,
	MAX(total_cases) AS HighestInfectionCount,
	MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC


-- 4.


--SELECT
--	Location,
--	Population,
--	date,
--	MAX(total_cases) AS HighestInfectionCount,
--	MAX((total_cases / population)) * 100 AS PercentPopulationInfected
--FROM PortfolioProject..CovidDeaths
--GROUP BY Location, Population, date
--ORDER BY PercentPopulationInfected DESC

-- With 7-day rolling average
SELECT
	location,
	population,
	date,
	new_cases,
	total_cases,
	ROUND
	(
		AVG(new_cases) 
		OVER (PARTITION BY location 
			ORDER BY date 
			ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),
		4
	) AS rolling_avg_7d,
	(total_cases / population) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
-- WHERE location LIKE 'malay%'
ORDER BY location, date


-- Find the maximum 7-day rolling average of daily cases for Malaysia
WITH rolling_avg AS (
SELECT
	location,
	population,
	date,
	new_cases,
	total_cases,
	ROUND
	(
		AVG(new_cases) 
		OVER (PARTITION BY location 
			ORDER BY date 
			ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),
		4
	) AS rolling_avg_7d,
	(total_cases / population) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location LIKE 'malay%'
)
SELECT location, date, rolling_avg_7d
FROM rolling_avg
	WHERE rolling_avg_7d = (
		SELECT MAX(rolling_avg_7d)
		FROM rolling_avg
		)










-- Queries that originally wanted for visualizations, but excluded because they are too long
-- Left here in case needed

-- 1.

SELECT dea.continent, dea.location, dea.date, dea.population
, MAX(vac.total_vaccinations) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 
GROUP BY dea.continent, dea.location, dea.date, dea.population
ORDER BY 1,2,3




-- 2.
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(New_Cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent is not null 
--GROUP BY date
ORDER BY 1,2


-- Just a double check based off the data provided
-- numbers are extremely close so we will keep them - The Second includes "International"  Location


--SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(New_Cases)*100 AS DeathPercentage
--FROM PortfolioProject..CovidDeaths
----WHERE location LIKE '%states%'
--WHERE location = 'World'
----GROUP BY date
--ORDER BY 1,2


-- 3.

-- We take these out AS they are not included in the above queries and want to stay consistent
-- European Union is part of Europe

SELECT location, SUM(CAST(new_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NULL 
and location not in ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC



-- 4.

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount,  MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC



-- 5.

--SELECT Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
--FROM PortfolioProject..CovidDeaths
----WHERE location LIKE '%states%'
--WHERE continent is not null 
--ORDER BY 1,2

-- took the above query and added population
SELECT Location, date, population, total_cases, total_deaths
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent is not null 
ORDER BY 1,2


-- 6. 


With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentPeopleVaccinated
FROM PopvsVac


-- 7. 

SELECT Location, Population,date, MAX(total_cases) AS HighestInfectionCount,  MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected DESC




