Select *
from Portsql..c19d
order by 3,4

select location, date, total_cases, new_cases, total_deaths, population
from Portsql..c19d
order by 1,2

-- Total cases & total deaths (%)
select location, date, total_cases, total_deaths, 
(total_deaths/total_cases*100) AS pc_of_deaths
from Portsql..c19d
order by 1,2
--(India)
select location, date, total_cases, total_deaths, 
(total_deaths/total_cases*100) AS pc_of_deaths
from Portsql..c19d
where location like 'India'  
order by 1,2

-- Total deaths vs population (India)
select location, date,(total_deaths/population) AS deaths_per_pop
from Portsql..c19d
where location like 'India'
order by 1,2

-- Countries with highest cases/population
select location, population, 
max(total_cases) as highest_infected, 
max(total_cases/population*100) AS pc_infected
from Portsql..c19d
group by location, population
order by pc_infected desc

-- Countries with highest deaths
select location, max(cast(total_deaths as int)) as death_count
from Portsql..c19d
where continent is not null
group by location


-- Countries with highest death rate per population
select location, population, 
max(cast(total_deaths/population*100 as float)) as pc_death_rate
from Portsql..c19d
group by location, population
order by pc_death_rate desc 

-- Continent wise highest death count
select continent, max(cast(total_deaths as int)) as pc_death_rate
from Portsql..c19d
where continent is not null
group by continent
order by pc_death_rate desc

-- worldwide total deaths & cases
select sum(new_cases) as total_new_cases, sum(cast(new_deaths as int)) as total_new_deaths
from Portsql..c19d
where continent is not null

-- Covid Tests/Vaccination related analysis -- 
select location, date,total_tests,new_tests, total_vaccinations,new_vaccinations
from Portsql..c19vax
order by location,date

-- Positive rate & total tests (%)--
--by continent
select continent,
sum(distinct(cast(total_tests as bigint))) as tt,avg(cast(positive_rate as float)) as pr
from Portsql..c19vax
where continent is not null
group by continent
order by pr desc

--by countries
select location,sum(distinct(cast(total_tests as bigint))) as tt,
avg(cast(positive_rate as float)) as pr
from Portsql..c19vax
group by location
order by pr desc

--for India
select location,date,total_tests,positive_rate 
from Portsql..c19vax
where location like 'India'
order by 2 
 
-- Total vaccinations country wise  
select distinct location,max(cast(total_vaccinations as bigint)) as vax_count
from Portsql..c19vax
where continent is not null
group by location 
order by vax_count desc

-- join
select *
from Portsql..c19d dt
join Portsql..c19vax vx
on dt.location = vx.location
and dt.date = dt.date

-- Total Vaccinations Population-wise(cumulative)

select dt.continent,dt.location,dt.date,dt.population,
sum(convert(int,vx.new_vaccinations)) over (partition by dt.location order by dt.location,dt.date) as rolling_count_vax
from Portsql..c19d dt
join Portsql..c19vax vx 
on dt.location=vx.location
and dt.date=vx.date
where dt.continent is not null
order by 2,3

--using CTE 
With popvsvax (continent,location,date,population,rolling_count_vax)
as
(
select dt.continent,dt.location,dt.date,dt.population,
sum(convert(bigint,vx.new_vaccinations)) over (partition by dt.location order by dt.location,dt.date) as rolling_count_vax
from Portsql..c19d dt
join Portsql..c19vax vx 
    on dt.location=vx.location
    and dt.date=vx.date
where dt.continent is not null
)
select *,rolling_count_vax/population*100 
from popvsvax

-- Temp table
Drop table if exists #PcPopVaxxed
create table #PcPopVaxxed
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
rolling_count_vax numeric
)

Insert into #PcPopVaxxed
(
continent,
location,
date,
population,
rolling_count_vax
)

select dt.continent,dt.location,dt.date,dt.population,
sum(convert(bigint,vx.new_vaccinations)) over (partition by dt.location order by dt.location,dt.date) as rolling_count_vax
from Portsql..c19d dt
join Portsql..c19vax vx 
    on dt.location=vx.location
    and dt.date=vx.date

select *,rolling_count_vax/population*100 as rolling_pc_vax
from #PcPopVaxxed



-- Create view for viz
drop view if exists PcPopVaxxed
go
CREATE VIEW PcPopVaxxed as
select dt.continent,dt.location,dt.date,dt.population,
sum(convert(bigint,vx.new_vaccinations)) over (partition by dt.location order by dt.location,dt.date) as rolling_count_vax
from Portsql..c19d dt
join Portsql..c19vax vx 
    on dt.location=vx.location
    and dt.date=vx.date
where dt.continent is not null
select *from PcPopVaxxed

CREATE VIEW DeathvsCases as
select location, date, total_cases, total_deaths, (total_deaths/total_cases*100) AS pc_of_deaths
from Portsql..c19d
--order by 1,2

CREATE VIEW CountryvsVax as
select distinct location,max(cast(total_vaccinations as bigint)) as vax_count
from Portsql..c19vax
where continent is not null
group by location 
--order by vax_count desc


CREATE VIEW CasesvsPop as
select location, population, max(total_cases) as highest_infected,
max(total_cases/population*100) AS pc_infected
from Portsql..c19d
group by location, population
--order by pc_infected desc


CREATE VIEW DeathvsPop as
select location, population, max(cast(total_deaths/population*100 as float)) as pc_death_rate
from Portsql..c19d
group by location, population
--order by pc_death_rate desc 


CREATE VIEW PosvsTest as
select location,sum(distinct(cast(total_tests as bigint))) as tt,
avg(cast(positive_rate as float)) as pr
from Portsql..c19vax
group by location
--order by pr desc

CREATE VIEW VaxvsCountry as
select distinct location,max(cast(total_vaccinations as bigint)) as vax_count
from Portsql..c19vax
where continent is not null
group by location 
--order by vax_count desc

