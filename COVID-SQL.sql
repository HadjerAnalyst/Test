
SELECT * FROM 
[dbo].[Covid Vaccination]
order by 3,4

--SELECT * FROM 
--[dbo].[CovidDeaths]
------------order by 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population from
[Portfolio SQL Prodjects]..CovidDeaths  
order by 1,2
-- looking at Total Deaths 

Select location, date, total_cases,total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
from [Portfolio SQL Prodjects]..CovidDeaths 
-- where location like 'France'
order by 1,2

-- looking at total cases & Population 
-- Shows what percentage of population got covid

Select location, date, total_cases, total_deaths,
(CONVERT(float, total_cases) / NULLIF(convert(float, Population),0)) * 100 AS PercentPopulationInfected
from [Portfolio SQL Prodjects]..CovidDeaths 
-- where location like 'France'
order by 1,2


-- looking at countries with highest infection rate compared to population 

Select Location, Population, max(total_cases) as HighestInfectionCount, 
max(CONVERT(float, total_cases) / NULLIF(convert(float, Population),0))  * 100 AS PercentPopulationInfected
From [Portfolio SQL Prodjects]..CovidDeaths 
-- where location like 'France'
group by location, Population
order by PercentPopulationInfected Desc 

-- looking at countries with highest Death count with population 

Select Location, max(cast(total_deaths as int)) as TotalDeathCount
From [Portfolio SQL Prodjects]..CovidDeaths 
-- where location like '%France%'
group by location
order by TotalDeathCount Desc 


-- Let's Break things down 

Select continent, max(cast(total_deaths as int)) as TotalDeathCount
From [Portfolio SQL Prodjects]..CovidDeaths 
--where location like 'France'
where continent is not null 
group by continent
order by TotalDeathCount Desc 

-- The following is wonderfull :  on a pas le mm résultat 
Select location, max(cast(total_deaths as int)) as TotalDeathCount
From [Portfolio SQL Prodjects]..CovidDeaths 
--where location like 'France'
where continent is not null 
group by location
order by TotalDeathCount Desc 

-- Showing continent with the highest death count per  population 

Select continent, max(cast(total_deaths as int)) as TotalDeathCount
From [Portfolio SQL Prodjects]..CovidDeaths 
--where location like 'France'
where continent is not null 
group by continent
order by TotalDeathCount Desc 

-- Global numbers 

Select
   date,
   sum(cast(new_cases AS int)) AS sum_new_cases,
   sum(cast(new_deaths AS int)) AS sum_new_deaths, 
--sum(cast(new_deaths as int))/nullif(sum(cast(new_cases as int)),0)*100  
(SUM(CAST(new_deaths AS INT)) / NULLIF(SUM(CAST(new_cases AS FLOAT)), 0)) * 100 AS death_rate_percentage
--, total_deaths, (CONVERT(float, total_cases) / NULLIF(convert(float, Population),0)) * 100 AS PercentPopulationInfected
from
     [Portfolio SQL Prodjects]..CovidDeaths 

-- where location like 'France'
where
     Continent is not null
group by
       date
order by 1,2

-- We need to replace the query by- select continent,  sum(new_deaths)
--from coviddeaths
--where continent!=''
--group by continent;
--Hope this helps


-- Looking at total population & Vaccination 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated,
--(RollingPeopleVaccinated/population) * 100
-- ou bien  sum(convert(int, vac.new_vaccinations)) over (partition by dea.location)

From [Portfolio SQL Prodjects]..CovidDeaths dea
join [dbo].[Covid Vaccination] vac 
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- use CTE 
with PopVsVac AS 
(
select
   dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
   sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population) * 100
-- ou bien  sum(convert(int, vac.new_vaccinations)) over (partition by dea.location)

From
    [Portfolio SQL Prodjects]..CovidDeaths dea
join
   [dbo].[Covid Vaccination] vac 
on 
   dea.location = vac.location
   and dea.date = vac.date
where
   dea.continent is not null 
--order by 2,3
) 
SELECT 
    continent, 
    location, 
    date, 
    population, 
    new_vaccinations, 
    RollingPeopleVaccinated, 
    (CAST(RollingPeopleVaccinated AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)) * 100 AS VaccinationRatePercentage
from PopVsVac

-- TEMP TABLE

IF OBJECT_ID('tempdb..#PercentPopulationVaccinated') IS NOT NULL
drop table if exists #PercentPopulationVaccinated;
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
Location nvarchar(255), 
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric 
) 
insert into #PercentPopulationVaccinated
select 
   dea.continent, 
   dea.location, dea.date,

   CASE 
        WHEN ISNUMERIC(dea.population) = 1 THEN CAST(dea.population AS NUMERIC) 
        ELSE NULL 
    END AS Population,
    CASE 
        WHEN ISNUMERIC(vac.new_vaccinations) = 1 THEN CAST(vac.new_vaccinations AS NUMERIC) 
        ELSE NULL 
    END AS New_vaccinations,

SUM(CASE 
        WHEN ISNUMERIC(vac.new_vaccinations) = 1 THEN CAST(vac.new_vaccinations AS NUMERIC) 
        ELSE 0 
    END) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population) * 100
-- ou bien  sum(convert(int, vac.new_vaccinations)) over (partition by dea.location)

From [Portfolio SQL Prodjects]..CovidDeaths dea
join [dbo].[Covid Vaccination] vac 
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
select *, (RollingPeopleVaccinated/population) * 100 
from #PercentPopulationVaccinated


--SELECT TRY_CONVERT(numeric, continent)
--FROM #PercentPopulationVaccinated;


-- Creating view to store data for later visualisation 

-- Drop the view if it exists
IF OBJECT_ID('dbo.PercentPopulationVaccinated', 'V') IS NOT NULL
    DROP VIEW dbo.PercentPopulationVaccinated;

-- Create the view
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date,
    CASE 
        WHEN ISNUMERIC(dea.population) = 1 THEN CAST(dea.population AS NUMERIC) 
        ELSE NULL 
    END AS Population,
    CASE 
        WHEN ISNUMERIC(vac.new_vaccinations) = 1 THEN CAST(vac.new_vaccinations AS NUMERIC) 
        ELSE NULL 
    END AS New_vaccinations,
    SUM(CASE 
        WHEN ISNUMERIC(vac.new_vaccinations) = 1 THEN CAST(vac.new_vaccinations AS NUMERIC) 
        ELSE 0 
    END) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM 
    [Portfolio SQL Prodjects]..CovidDeaths dea
JOIN 
    [dbo].[Covid Vaccination] vac 
ON 
    dea.location = vac.location 
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;

--TO VISUALIZE 
SELECT * FROM PercentPopulationVaccinated