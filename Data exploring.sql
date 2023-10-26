-- CREATE TABLE 
use nyc_airbnb;
drop table if exists listing;
create table listing
(
id int,
host_id int,
host_name varchar(255),
neighbourhood_group varchar(255),
neighbourhood varchar(255),
room_type varchar(255),
price int,
minimum_nights int,
number_of_reviews int,
last_review varchar(255),
reviews_per_month varchar(50),
calculated_host_listings_count int,
availability_365 int,
number_of_reviews_ltm int,
license varchar(255),
property_type varchar(255),
rating varchar(255),
bedrooms varchar(255),
beds varchar(255),
baths varchar(255)
);


 -- LOAD INFILE DATA
	load data infile 'nyc_listings1.csv' into table listing
	fields terminated by ','
	ignore 1 lines;

-- CHECK DATA
	select *
	from nyc_airbnb.listing;
    
    select *
    from crime;
    
-- CREATE AND STORE TEMPORARY LISTING JOINED CRIME TABLE 
	drop temporary table listings_crime;
    
    delimiter //
    create procedure listings_crime()
    begin
	create temporary table listings_crime 
	select l.*, c.*
	from listing l 
	left join crime c on l.neighbourhood = c.name;
    select * from listings_crime;
    end //
    
    delimiter ;
    call listings_crime();

-- EXPLORE DATASET 

#Top 5 most expensive neighbourhood
	with listings_with_ranking as (
		select 
			dense_rank() over (order by avg(price) desc) as ranking, 
            neighbourhood, 
            concat( '$', format(avg(price),2)) as avg_price
            from listing
            group by neighbourhood
	)
    select * 
    from listings_with_ranking
    limit 5;
    
#Top 5 most populated neighbourhood
	with listings_with_ranking as (
		select 
			dense_rank() over (order by count(id) desc) as ranking, 
            neighbourhood, 
            count(id) as listings_count
            from listing
            group by neighbourhood
	)
    select * 
    from listings_with_ranking
    limit 5;
    
#what are neighborhood with crime rate higher than neighborhood group average property & violent crime rate? 
	select l.id, l.property_type, l.neighbourhood, concat('$', l.price) as price, 
	 case
		when property_crime > avg_property_crime then 'dangerous'
		when violent_crime > avg_violent_crime then 'dangerous'
		else 'safe'
		end as safety_level
	from listings_crime l inner join crime_by_neighborhoodgroup c on l.neighbourhood_group = c.neighbourhood_group
	order by price asc
	limit 10;
    
#What are neighborhood group with highest property_crime_rate and violent_crime_rate
	drop temporary table crime_by_neighborhoodgroup;
	create temporary table crime_by_neighborhoodgroup
	select neighbourhood_group, format(avg(property_crime),2) as avg_property_crime, format(avg(violent_crime),2) as avg_violent_crime
	from listings_crime
	group by neighbourhood_group;
	select * from crime_by_neighborhoodgroup;

#Calculate the Pearson correlation coefficient between price and property crime rate
	drop temporary table if exists price_property_crime;
    -- Filter out rows with valid numeric data
    create temporary table price_property_crime as
    select
		cast(price as decimal) as price,
		cast(property_crime as decimal) as property_crime
	from listings_crime
	where price is not null and property_crime is not null;
	-- Calculate the correlation coefficient
	select  
			-- For Sample
			(count(*) * sum(property_crime * price) - sum(property_crime) * sum(price)) / 
			(sqrt(count(*) * sum(property_crime * property_crime) - sum(property_crime) * sum(property_crime)) * sqrt(count(*) * sum(price * price) - sum(price) * sum(price))) 
			as correlation_coefficient_sample
		from price_property_crime;


    



