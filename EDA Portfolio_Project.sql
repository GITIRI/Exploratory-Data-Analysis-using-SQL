/*
Covid 19 Data Exploration Project

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types & Aliasing

Data source: http://www.ourworldindata.org/

*/

-- Checking whether all the data imported correctly

SELECT *
FROM portfolio_project..coviddeaths
WHERE continent is not null
ORDER BY 3,4

SELECT *
FROM portfolio_project..covidvaccinations
WHERE continent is not null
ORDER BY 3,4

-- Selecting the data that I will use in this project 

 SELECT location, date, total_cases, new_cases, total_deaths, population
 FROM portfolio_project..coviddeaths
 WHERE continent is not null
 ORDER BY location, date


-- total_deaths VS total_cases 
--shows likelihood of death for people who have contracted COVID in Kenya

SELECT location, date, total_cases, total_deaths , ROUND(((total_deaths / total_cases) * 100) , 2) as Percentage_Deaths
FROM portfolio_project..coviddeaths
WHERE location like 'Kenya'
AND continent is not null
ORDER BY location, date


-- total_cases VS population
--shows the percentage of the population that got COVID in Kenya

SELECT location, date, total_cases, population , ROUND(((total_cases / population ) * 100) , 2) as Percentage_Cases
FROM portfolio_project..coviddeaths
WHERE location like 'Kenya'
AND continent is not null
ORDER BY location, date


-- Countries with the highest rate of infection

SELECT location, MAX(total_cases) AS Highest_Infection_Count , MAX(ROUND(((total_cases / population) * 100) , 2)) as Percentage_Cases
FROM portfolio_project..coviddeaths
WHERE continent is not null
GROUP BY location, Population
ORDER BY Percentage_Cases DESC


--Countries with the highest death count against the population

SELECT location, MAX (CAST(total_deaths as INT)) AS Total_Death_Count 
FROM portfolio_project..coviddeaths
WHERE continent is not null
GROUP BY location
ORDER BY Total_Death_Count DESC


--Death Count by Continent

SELECT location, MAX (CAST(total_deaths as INT)) AS Total_Death_Count_By_Continent
FROM portfolio_project..coviddeaths
WHERE continent is null
GROUP BY location
ORDER BY Total_Death_Count_By_Continent DESC


-- Global Numbers by Date (Cases & Deaths)

SELECT date, SUM (new_cases) AS Total_Cases , SUM (CAST (new_deaths AS INT)) AS Total_deaths,  ROUND((( SUM (CAST (new_deaths AS INT))/  SUM (new_cases)) * 100) , 2) as Percentage_New_Deaths
FROM portfolio_project..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2 


-- Global Numbers (Cases & Deaths)

SELECT SUM (new_cases) AS Total_Cases , SUM (CAST (new_deaths AS INT)) AS Total_deaths,  ROUND((( SUM (CAST (new_deaths AS INT))/  SUM (new_cases)) * 100) , 2) as Percentage_New_Deaths
FROM portfolio_project..CovidDeaths
WHERE continent is not null


--JOIN Deaths and Vaccinations Tables 
--Create new Aliases for the table names

SELECT *
FROM portfolio_project..CovidDeaths Dea
JOIN Portfolio_Project.dbo.CovidVaccinations Vacc
  ON Dea.iso_code = Vacc.iso_code
  AND Dea.date = Vacc.date
ORDER BY 3,4


--TOTAL NUMBER OF PEOPLE VACCINATED

SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vacc.new_vaccinations
,SUM (CONVERT (int, Vacc.new_vaccinations)) OVER (partition by Dea.location  Order by Dea.location, Dea.date) as Rolling_Vaccinations_Count
FROM portfolio_project..CovidDeaths Dea
JOIN Portfolio_Project.dbo.CovidVaccinations Vacc
  ON Dea.location = Vacc.location
  AND Dea.date = Vacc.date
WHERE Dea.continent IS NOT NULL
ORDER BY 2,3


--USING CTEs  
--This will help us make use of the new column Rolling_Vaccinations_Count in calculations

WITH POPvsVACC AS
( 
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vacc.new_vaccinations
,SUM (CONVERT (int, Vacc.new_vaccinations)) OVER (partition by Dea.location  Order by Dea.location, Dea.date) as Rolling_Vaccinations_Count
FROM portfolio_project..CovidDeaths Dea
JOIN Portfolio_Project.dbo.CovidVaccinations Vacc
  ON Dea.location = Vacc.location
  AND Dea.date = Vacc.date
WHERE Dea.continent IS NOT NULL
)
SELECT*, (Rolling_Vaccinations_Count/population ) *100 AS Percentage_Vaccinations
FROM POPvsVACC


--USING TEMP TABLE

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_Vaccinations_Count numeric
)

INSERT into #PercentPopulationVaccinated
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vacc.new_vaccinations
, SUM(CONVERT(int,Vacc.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as Rolling_Vaccinations_Count
--, (RollingPeopleVaccinated/population)*100
From Portfolio_Project..CovidDeaths Dea
Join Portfolio_Project..CovidVaccinations Vacc
	On dea.location = Vacc.location
	and dea.date = Vacc.date
--where dea.continent is not null 
--order by 2,3

SELECT *, (Rolling_Vaccinations_Count/Population)*100 AS Percentage_Vaccinations
FROM #PercentPopulationVaccinated




--CREATING A VIEW TO STORE DATA FOR USE IN VISUALIZATIONS

USE [Portfolio_Project]
GO

CREATE VIEW Percent_Population_Vaccinated AS
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vacc.new_vaccinations
, SUM(CONVERT(int,Vacc.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as Rolling_Vaccinations_Count
--, (RollingPeopleVaccinated/population)*100
From Portfolio_Project..CovidDeaths Dea
Join Portfolio_Project..CovidVaccinations Vacc
	On dea.location = Vacc.location
	and dea.date = Vacc.date
where dea.continent is not null 

SELECT *
FROM Percent_Population_Vaccinated




