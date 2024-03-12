-- Select Data we are going to use

select continent, location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
where continent IS NOT NULL
Order by 1,2

-- Looking at Total cases vs Total Deaths
--Shows likelihood of dying if you contract Covid in your country
select continent, location, date, total_deaths, (cast(total_deaths as float)/total_cases)*100 as DeathPercentage 
From PortfolioProject..CovidDeaths
where continent IS NOT NULL
Order by 1,2

-- Looking as Total Cases vs Population
-- Shows what percentage og population got Covid
select location, date,population,  total_cases, (total_cases/population)*100 as 'PercentPopulationInfected'
From PortfolioProject..CovidDeaths
where continent IS NOT NULL
Order by 1,2

--Looking at countries with highest infection rate compared to Population
select location, population, MAX(total_cases) as HighestInfectionCount, (MAX(total_cases)/population)*100 as 'PercentPopulationInfected'
From PortfolioProject..CovidDeaths
where continent IS NOT NULL
group by location, population
Order by 'PercentPopulationInfected' DESC

--Showing countries with highest Death Count per Population
Select continent, location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent IS NOT NULL
Group by continent, location
Order by 'TotalDeathCount' DESC


--Showing continents with the highest Death Count
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent IS NOT NULL and location  not like '%income%'
Group by continent
Order by 'TotalDeathCount' DESC

--Global numbers
Select date, sum(new_cases) as total_cases, sum(new_deaths) as total_deaths,   CASE 
        WHEN SUM(new_cases) = 0 THEN NULL -- Avoid division by zero
        ELSE SUM(new_deaths) / SUM(new_cases) * 100
    END AS death_rate
From PortfolioProject..CovidDeaths
Where continent IS NOT NULL 
Group by date
order by 1,2

--Total population VS Vaccinated
with PopulationvsVaccinated (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as (
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		sum(Case
		WHEN vac.new_vaccinations is NULL then 0
		ELSE CONVERT(bigint, vac.new_vaccinations)
		END) OVER (partition by dea.location order by dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
	join PortfolioProject..CovidVaccinations vac
	on dea.location=vac.location and dea.date=vac.date
Where dea.continent IS NOT NULL 
)
select *, (RollingPeopleVaccinated/population)*100 as PercentageOfVac
FROM PopulationvsVaccinated
order by location

--Temp Table
Drop Table if exists #PercentPoplationVaccinated
Create Table #PercentPoplationVaccinated
(continent nvarchar(255),
Location nvarchar(255),
Date datetime,
population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPoplationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		sum(Case
		WHEN vac.new_vaccinations is NULL then 0
		ELSE CONVERT(bigint, vac.new_vaccinations)
		END) OVER (partition by dea.location order by dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
	join PortfolioProject..CovidVaccinations vac
	on dea.location=vac.location 
	and dea.date=vac.date
Where dea.continent IS NOT NULL 
Order by dea.location

Select *
From #PercentPoplationVaccinated