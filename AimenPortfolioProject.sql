SELECT TOP(5000) *
FROM PortfolioProject.dbo.CovidDeath
ORDER BY 3,4

SELECT TOP(5000) *
FROM PortfolioProject.dbo.CovidVaccinations
ORDER BY 3,4


-- Selecting relevant data
SELECT CovidDeath.Location, 
		CovidDeath.date, 
		CovidDeath.total_cases, 
		CovidDeath.new_cases, 
		CovidDeath.total_deaths, 
		Populations.population
FROM PortfolioProject.dbo.CovidDeath
LEFT JOIN PortfolioProject.dbo.Populations
ON PortfolioProject.dbo.Populations.iso_code = PortfolioProject.dbo.CovidDeath.iso_code
WHERE CovidDeath.Continent IS NOT NULL
ORDER BY 1,2

-- Looking at total cases vs total deaths
SELECT CovidDeath.Location, 
		CovidDeath.date, 
		CovidDeath.total_cases, 
		CovidDeath.total_deaths, 
		(total_deaths/NULLIF(total_cases,0)*100) as death_percentage
FROM PortfolioProject.dbo.CovidDeath
WHERE CovidDeath.Continent IS NOT NULL
ORDER BY 1,2

-- Looking at total case to population ratio to see what percentage of population got infected
SELECT CovidDeath.Location, 
		CovidDeath.date, 
		CovidDeath.total_cases, 
		CovidDeath.new_cases, 
		CovidDeath.total_deaths, 
		Populations.population, 
		(CovidDeath.total_cases/Populations.population*100) as case_percentage
FROM PortfolioProject.dbo.CovidDeath
LEFT JOIN PortfolioProject.dbo.Populations
ON PortfolioProject.dbo.Populations.iso_code = PortfolioProject.dbo.CovidDeath.iso_code
WHERE CovidDeath.Continent IS NOT NULL
ORDER BY 1,2;

-- Looking at Countries with highest infection rate compared to population
SELECT CovidDeath.Location, 
		MAX(CovidDeath.total_cases) as highest_infection_count, 
		Populations.population, 
		(MAX(CovidDeath.total_cases)/Populations.population*100) as percent_population_infected
FROM PortfolioProject.dbo.CovidDeath
LEFT JOIN PortfolioProject.dbo.Populations
ON PortfolioProject.dbo.Populations.iso_code = PortfolioProject.dbo.CovidDeath.iso_code
WHERE CovidDeath.Continent IS NOT NULL
GROUP BY CovidDeath.Location, 
			Populations.population
ORDER BY percent_population_infected DESC;

-- Looking at Countries with death count per population
SELECT CovidDeath.Location, 
		MAX(CovidDeath.total_deaths) as highest_death_count, 
		Populations.population, 
		(MAX(CovidDeath.total_deaths)/Populations.population*100) as total_death_percentage
FROM PortfolioProject.dbo.CovidDeath
LEFT JOIN PortfolioProject.dbo.Populations
ON PortfolioProject.dbo.Populations.iso_code = PortfolioProject.dbo.CovidDeath.iso_code
WHERE CovidDeath.Continent IS NOT NULL
GROUP BY CovidDeath.Location, 
		Populations.population
ORDER BY total_death_percentage DESC;

-- Looking at countries with highest magnitude of death count
SELECT CovidDeath.Location, 
		MAX(CovidDeath.total_deaths) as highest_death_count
FROM PortfolioProject.dbo.CovidDeath
WHERE CovidDeath.Continent IS NOT NULL
GROUP BY CovidDeath.Location
ORDER BY highest_death_count DESC;

-- Continental break down of data
SELECT CovidDeath.Location, MAX(CovidDeath.total_deaths) as highest_death_count
FROM PortfolioProject.dbo.CovidDeath
WHERE CovidDeath.Continent IS NULL
GROUP BY CovidDeath.Location
ORDER BY highest_death_count DESC;

-- Showing continents with highest death count per population
SELECT CovidDeath.Location, 
		MAX(CovidDeath.total_deaths) as highest_death_count, 
		Populations.population, 
		(MAX(CovidDeath.total_deaths)/Populations.population*100) as total_death_percentage
FROM PortfolioProject.dbo.CovidDeath
LEFT JOIN PortfolioProject.dbo.Populations
ON PortfolioProject.dbo.Populations.iso_code = PortfolioProject.dbo.CovidDeath.iso_code
WHERE CovidDeath.Continent IS NULL
GROUP BY CovidDeath.Location, 
		Populations.population
ORDER BY total_death_percentage DESC;

--global statistics

SELECT CovidDeath.date, 
		MAX(CovidDeath.total_deaths) as highest_death_count, 
		MAX(total_cases) as highest_case_count, 
		(MAX(total_deaths)/NULLIF(MAX(total_cases),0))*100 as death_percentage
FROM PortfolioProject.dbo.CovidDeath
WHERE CovidDeath.Continent IS NOT NULL
GROUP BY CovidDeath.date
ORDER BY 1,2

-- Looking at Total Population vs Vaccinations
-- USING CTE

WITH PopvsVaxx (continent, Location, date, population, rolling_people_vaccinated, new_vaccinations)
AS
(SELECT death.continent, 
		death.Location, 
		death.date, 
		pop.population, 
		vaxx.new_vaccinations,
		SUM(new_vaccinations) OVER (PARTITION BY death.Location ORDER BY death.Location,death.date)
			AS rolling_people_vaccinated
	FROM PortfolioProject..CovidDeath death
	JOIN PortfolioProject..CovidVaccinations vaxx
		ON death.Location = vaxx.Location
		AND death.date = vaxx.date
	JOIN PortfolioProject..Populations pop
		ON pop.iso_code = death.iso_code
	WHERE death.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/population)*100
FROM PopvsVaxx

-- USING TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	new_vaccinations numeric,
	rolling_people_vaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT death.continent, 
		death.Location, 
		death.date, 
		pop.population, 
		vaxx.new_vaccinations,
		SUM(new_vaccinations) OVER (PARTITION BY death.Location ORDER BY death.Location,death.date)
			AS rolling_people_vaccinated
	FROM PortfolioProject..CovidDeath death
	JOIN PortfolioProject..CovidVaccinations vaxx
		ON death.Location = vaxx.Location
		AND death.date = vaxx.date
	JOIN PortfolioProject..Populations pop
		ON pop.iso_code = death.iso_code
	WHERE death.continent IS NOT NULL

SELECT *, (rolling_people_vaccinated/population)*100
FROM #PercentPopulationVaccinated

-- Creating view to store data for visualizations
DROP VIEW IF EXISTS PercentPopulationVaccinated
CREATE VIEW PercentPopulationVaccinated AS
SELECT death.continent, 
		death.Location, 
		death.date, 
		pop.population, 
		vaxx.new_vaccinations,
		SUM(new_vaccinations) OVER (PARTITION BY death.Location ORDER BY death.Location,death.date)
			AS rolling_people_vaccinated
	FROM PortfolioProject..CovidDeath death
	JOIN PortfolioProject..CovidVaccinations vaxx
		ON death.Location = vaxx.Location
		AND death.date = vaxx.date
	JOIN PortfolioProject..Populations pop
		ON pop.iso_code = death.iso_code
	WHERE death.continent IS NOT NULL
;
DROP VIEW IF EXISTS GlobalStatistics
CREATE VIEW GlobalStatistics AS
	SELECT CovidDeath.date, 
			MAX(CovidDeath.total_deaths) as highest_death_count, 
			MAX(total_cases) as highest_case_count, 
			(MAX(total_deaths)/NULLIF(MAX(total_cases),0))*100 as death_percentage
	FROM PortfolioProject.dbo.CovidDeath
	WHERE CovidDeath.Continent IS NOT NULL
	GROUP BY CovidDeath.date
;
DROP VIEW IF EXISTS DeathCount
CREATE VIEW DeathCount AS
	SELECT CovidDeath.Location, 
			MAX(CovidDeath.total_deaths) as highest_death_count, 
			Populations.population, 
			(MAX(CovidDeath.total_deaths)/Populations.population*100) as total_death_percentage
	FROM PortfolioProject.dbo.CovidDeath
	LEFT JOIN PortfolioProject.dbo.Populations
	ON PortfolioProject.dbo.Populations.iso_code = PortfolioProject.dbo.CovidDeath.iso_code
	WHERE CovidDeath.Continent IS NULL
	GROUP BY CovidDeath.Location, Populations.population
;
DROP VIEW IF EXISTS ContinentalData
CREATE VIEW ContinentalData AS
	SELECT CovidDeath.Location, 
	MAX(CovidDeath.total_deaths) as highest_death_count	
	FROM PortfolioProject.dbo.CovidDeath
	WHERE CovidDeath.Continent IS NULL
	GROUP BY CovidDeath.Location
;
DROP VIEW IF EXISTS HighestDeathCount
CREATE VIEW HighestDeathCount AS
	SELECT CovidDeath.Location, 
			MAX(CovidDeath.total_deaths) as highest_death_count
	FROM PortfolioProject.dbo.CovidDeath
	WHERE CovidDeath.Continent IS NOT NULL
	GROUP BY CovidDeath.Location
;
DROP VIEW IF EXISTS HighestDeathCountPerCapita
CREATE VIEW HighestDeathCountPerCapita AS
	SELECT CovidDeath.Location, 
			MAX(CovidDeath.total_deaths) as highest_death_count, 
			Populations.population, 
			(MAX(CovidDeath.total_deaths)/Populations.population*100) as total_death_percentage
	FROM PortfolioProject.dbo.CovidDeath
	LEFT JOIN PortfolioProject.dbo.Populations
	ON PortfolioProject.dbo.Populations.iso_code = PortfolioProject.dbo.CovidDeath.iso_code
	WHERE CovidDeath.Continent IS NOT NULL
	GROUP BY CovidDeath.Location, Populations.population
;
DROP VIEW IF EXISTS HighestInfectionPerCapita
CREATE VIEW HighestInfectionPerCapita AS
	SELECT CovidDeath.Location, 
			MAX(CovidDeath.total_cases) as highest_infection_count, 
			Populations.population, 
			(MAX(CovidDeath.total_cases)/Populations.population*100) as percent_population_infected
	FROM PortfolioProject.dbo.CovidDeath
	LEFT JOIN PortfolioProject.dbo.Populations
	ON PortfolioProject.dbo.Populations.iso_code = PortfolioProject.dbo.CovidDeath.iso_code
	WHERE CovidDeath.Continent IS NOT NULL
	GROUP BY CovidDeath.Location, 
				Populations.population
;
DROP VIEW IF EXISTS InfectedPopulation
CREATE VIEW InfectedPopulation AS
	SELECT CovidDeath.Location, 
			CovidDeath.date, 
			CovidDeath.total_cases, 
			CovidDeath.new_cases, 
			CovidDeath.total_deaths, 
			Populations.population, 
			(CovidDeath.total_cases/Populations.population*100) as case_percentage
	FROM PortfolioProject.dbo.CovidDeath
	LEFT JOIN PortfolioProject.dbo.Populations
	ON PortfolioProject.dbo.Populations.iso_code = PortfolioProject.dbo.CovidDeath.iso_code
	WHERE CovidDeath.Continent IS NOT NULL
;
DROP VIEW IF EXISTS TotalDeathsCases
CREATE VIEW TotalDeathsCases AS
	SELECT CovidDeath.Location, 
			CovidDeath.date, 
			CovidDeath.total_cases, 
			CovidDeath.total_deaths, 
			(total_deaths/NULLIF(total_cases,0)*100) as death_percentage
	FROM PortfolioProject.dbo.CovidDeath
	WHERE CovidDeath.Continent IS NOT NULL
;
DROP VIEW IF EXISTS DeathSummaryData
CREATE VIEW DeathSummaryData AS
	SELECT CovidDeath.Location, 
			CovidDeath.date, 
			CovidDeath.total_cases, 
			CovidDeath.new_cases, 
			CovidDeath.total_deaths, 
			Populations.population
	FROM PortfolioProject.dbo.CovidDeath
	LEFT JOIN PortfolioProject.dbo.Populations
	ON PortfolioProject.dbo.Populations.iso_code = PortfolioProject.dbo.CovidDeath.iso_code
	WHERE CovidDeath.Continent IS NOT NULL
;


