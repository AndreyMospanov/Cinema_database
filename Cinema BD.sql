CREATE DATABASE Cinema;
GO
USE [Cinema];
GO

CREATE TABLE Movies
(
id INT PRIMARY KEY IDENTITY(1,1),
movie_name NVARCHAR(MAX) NOT NULL CHECK(movie_name != ''),
length INT NOT NULL CHECK(length > 0),	--movie duration in minutes
genre NVARCHAR(50) NOT NULL CHECK(genre != ''),
year INT NOT NULL CHECK(year > 1880 AND year <= YEAR(GETDATE())),
poster VARCHAR(MAX),			--reference to pic with poster
price_multiplier FLOAT DEFAULT 1.0,	
age_restriction INT NOT NULL DEFAULT 18	
);

CREATE TABLE Clients
(
id INT PRIMARY KEY IDENTITY(1,1),
client_name NVARCHAR(MAX) NOT NULL CHECK(client_name != ''),
email VARCHAR(MAX),
birthdate DATE NOT NULL
);

CREATE TABLE Halls
(
id INT PRIMARY KEY IDENTITY(1,1),
hall_name NVARCHAR(MAX) NOT NULL CHECK(hall_name != ''),
capacity INT NOT NULL CHECK(capacity > 0),
row INT NOT NULL CHECK(row > 0),	--max row count in the hall
seat INT NOT NULL CHECK(seat > 0)	--max seats count in the hall
);

CREATE TABLE Schedule
(
id INT PRIMARY KEY IDENTITY (1,1),
movie_id INT NOT NULL REFERENCES Movies(id) ON DELETE NO ACTION,
hall_id INT NOT NULL REFERENCES Halls(id) ON DELETE NO ACTION,
show_time DATETIME NOT NULL CHECK (show_time > GETDATE()),
price MONEY NOT NULL DEFAULT 200,
price_multiplier FLOAT DEFAULT 1.0		--price multiplier depending on time of show 
);

CREATE TABLE Orders
(
id INT PRIMARY KEY IDENTITY (1,1),
client_id INT NOT NULL REFERENCES Clients(id) ON DELETE NO ACTION,
schedule_id INT NOT NULL REFERENCES Schedule(id) ON DELETE NO ACTION,
booking BIT NOT NULL DEFAULT 0,		--order status: ticket booked if value equals 1
sold BIT NOT NULL DEFAULT 0,		--order status: ticket sold if value equals 1
order_date DATETIME DEFAULT GETDATE()
);

