--select * from dbo.CovidVaccinations
--order by 3,4

--select * from dbo.CovidDeaths
--order by 3,4

-- Selecting data that we are going to use

select location,date,total_cases,new_cases,total_deaths,population
from dbo.CovidDeaths
where continent is not null
order by 1,2 

-- Looking at Total cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
from dbo.CovidDeaths
where continent is not null and location like '%states%'
order by 1,2 

-- Looking at Total cases vs Population
-- Shows % of total population who got covid

select location,date,population,total_cases,(total_cases/population)*100 as CovidPercentage
from dbo.CovidDeaths
where continent is not null
--where location like '%states%'
order by 1,2 

-- Looking at countries with highest infection rate compared to population

select location,population,MAX(total_cases) as HighestInfectionCount,MAX((total_cases/population))*100 as CovidPercentage
from dbo.CovidDeaths
where continent is not null
Group By location,population
order by CovidPercentage desc

-- Showing countries with highest death count per population
-- Since total_deaths field is of nvarchar, we need to cast it to integer to perform precise calculation

select location,MAX(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths
where continent is not null
Group By location
order by TotalDeathCount desc

-- Showing data by continent

select continent,MAX(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths
where continent is not null
Group By continent
order by TotalDeathCount desc

-- Global numbers by date

select date,sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from dbo.CovidDeaths
where continent is not null
group by date
order by 1,2

-- Total cases and deaths in world

select sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from dbo.CovidDeaths
where continent is not null
order by 1,2

-- Looking at total population vs vaccinations

select d.continent,d.location,d.date,d.population, v.new_vaccinations
from dbo.CovidDeaths d join dbo.CovidVaccinations v 
on d.location = v.location and d.date = v.date
where d.continent is not null
order by 2,3

-- Looking at total population vs vaccinations by running total of new vaccinations

select d.continent,d.location,d.date,d.population, v.new_vaccinations, 
sum(cast(v.new_vaccinations as int)) over (partition by d.location order by d.location,d.date ) as RunningTotalofVaccinations
--(RunningTotalofVaccinations/population)*100
from dbo.CovidDeaths d join dbo.CovidVaccinations v 
on d.location = v.location and d.date = v.date
where d.continent is not null
order by 2,3

-- USE CTE to find % of vaccinated over total population (METHOD 1)

With PopvsVac (Continent,Location,Date,Population,New_Vaccinations,RunningTotalofVaccinations)
AS
(
select d.continent,d.location,d.date,d.population, v.new_vaccinations, 
sum(cast(v.new_vaccinations as int)) over (partition by d.location order by d.location,d.date ) as RunningTotalofVaccinations
--(RunningTotalofVaccinations/population)*100
from dbo.CovidDeaths d join dbo.CovidVaccinations v 
on d.location = v.location and d.date = v.date
where d.continent is not null
)

select *,(RunningTotalofVaccinations/population)*100 as PercentageVaccinated from PopvsVac

-- Using TEMP Table (Method 2)

DROP TABLE IF EXISTS #PercentPeopleVaccinated
CREATE TABLE #PercentPeopleVaccinated
(
Continent nvarchar(256),
Location nvarchar(256),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RunningTotalofVaccinations numeric
)

INSERT INTO #PercentPeopleVaccinated
select d.continent,d.location,d.date,d.population, v.new_vaccinations, 
sum(cast(v.new_vaccinations as int)) over (partition by d.location order by d.location,d.date ) as RunningTotalofVaccinations
from dbo.CovidDeaths d join dbo.CovidVaccinations v 
on d.location = v.location and d.date = v.date
where d.continent is not null

select *,(RunningTotalofVaccinations/population)*100 as PercentageVaccinated from #PercentPeopleVaccinated
WHERE Location IN ('INDIA')
ORDER BY 2,3

-- Creating view

create view PercentPeopleVaccinated AS 
select d.continent,d.location,d.date,d.population, v.new_vaccinations, 
sum(cast(v.new_vaccinations as int)) over (partition by d.location order by d.location,d.date ) as RunningTotalofVaccinations
from dbo.CovidDeaths d join dbo.CovidVaccinations v 
on d.location = v.location and d.date = v.date
where d.continent is not null

SELECT * FROM PercentPeopleVaccinated
