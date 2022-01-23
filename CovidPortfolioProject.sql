Select *
From [PortfolioProject ]..CovidDeaths$
Where continent is not null
order by 3,4

Select *
From [PortfolioProject ]..CovidVaccinations$

--Select the data we are going to be using.

Select Location, date, total_cases, new_cases, total_deaths, population
From [PortfolioProject ]..CovidDeaths$
Order by 1,2


--Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract Covid in your country.

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From [PortfolioProject ]..CovidDeaths$
Where location like '%states%'
Order by 1,2


--Looking at the Total Cases vs Population
--Shows what percentage of population has gotten Covid.
Select Location, date, Population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From [PortfolioProject ]..CovidDeaths$
--Where location like '%states%'
Order by 1,2


--Looking at Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From [PortfolioProject ]..CovidDeaths$
--Where location like '%states%'
Group By Population, Location
Order by PercentPopulationInfected Desc


--Showing Countries with the Highest Death Count per Population


Select Location, Population, MAX(cast(total_deaths as int)) as TotalDeathCount
From [PortfolioProject ]..CovidDeaths$
--Where location like '%states%'
Where continent is not null
Group By Population, Location
Order by TotalDeathCount Desc


--Lets break things down by continent


--Showing the continents with the highest death count per population

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From [PortfolioProject ]..CovidDeaths$
--Where location like '%states%'
Where continent is not null
Group By continent
Order by TotalDeathCount Desc



--GLOBAL NUMBERS

Select  date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths , SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From [PortfolioProject ]..CovidDeaths$
--Where location like '%states%'
where continent is not null
Group by date
Order by 1,2


Select  SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From [PortfolioProject ]..CovidDeaths$
--Where location like '%states%'
where continent is not null
--Group by date
Order by 1,2



--Looking at Total Population vs Vaccinations

--Using common table expression (CTE)

With PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population) * 100
From [PortfolioProject ]..CovidDeaths$ dea
Join 
[PortfolioProject ]..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--Order by 1,2, 3
)
Select *, (RollingPeopleVaccinated/Population) * 100
From PopvsVac



-- TEMP TABLE

Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
NewVaccinations numeric,
RollingPeopleVaccinated numeric
)



Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population) * 100
From [PortfolioProject ]..CovidDeaths$ dea
Join 
[PortfolioProject ]..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--Order by 1,2, 3


Select *, (RollingPeopleVaccinated/Population) * 100
From #PercentPopulationVaccinated


--Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population) * 100
From [PortfolioProject ]..CovidDeaths$ dea
Join 
[PortfolioProject ]..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--Order by 2, 3

Select *
From PercentPopulationVaccinated