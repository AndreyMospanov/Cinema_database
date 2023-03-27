USE [master];
GO
IF DB_ID('Cinema') IS NOT NULL
BEGIN
	DROP DATABASE[Cinema];
END

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
age_restriction INT DEFAULT 18	
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
price MONEY NOT NULL DEFAULT 200
);

CREATE TABLE Orders
(
id INT PRIMARY KEY IDENTITY (1,1),
client_id INT NOT NULL REFERENCES Clients(id) ON DELETE NO ACTION,
schedule_id INT NOT NULL REFERENCES Schedule(id) ON DELETE NO ACTION,
row INT NOT NULL,
seat INT NOT NULL,
booking BIT NOT NULL DEFAULT 0,		--order status: ticket booked if value equals 1
sold BIT NOT NULL DEFAULT 0,		--order status: ticket sold if value equals 1
order_date DATETIME DEFAULT GETDATE()
);

GO
CREATE VIEW Schedule_FullView
AS
SELECT movie_name AS Movie, hall_name AS Hall, show_time AS Time, price  FROM Schedule
JOIN Movies ON Schedule.movie_id = Movies.id
JOIN Halls ON Schedule.hall_id = Halls.id

GO
CREATE PROCEDURE sp_movie_sells	--сколько выручено за конкретный фильм
@name NVARCHAR(30)
AS
BEGIN
SELECT movie_name, SUM(Schedule.price) FROM Orders AS o
JOIN Schedule ON o.schedule_id = Schedule.id
JOIN Movies ON Schedule.movie_id = Movies.id
WHERE movie_name = @name AND o.sold = 1
GROUP BY movie_name
END

GO --сколько билетов продано
CREATE PROCEDURE sp_tickets_sold
@name NVARCHAR(30)
AS
BEGIN
SELECT movie_name, COUNT(schedule_id) AS Tickets_count FROM Orders AS o
JOIN Schedule ON o.schedule_id = Schedule.id
JOIN Movies ON Schedule.movie_id = Movies.id
WHERE movie_name = @name AND o.sold = 1
GROUP BY movie_name
END

GO
CREATE PROCEDURE sp_book_ticket--бронирование билетов
@row INT,
@seat INT,
@schedule_id INT,
@client_id INT
AS
IF((SELECT row FROM Halls JOIN Schedule AS s ON s.hall_id = Halls.id WHERE s.id = @schedule_id) <= @row)
BEGIN
	IF((SELECT seat FROM Halls JOIN Schedule AS s ON s.hall_id = Halls.id WHERE s.id = @schedule_id) <= @seat)
	BEGIN
		INSERT INTO Orders VALUES
		(@client_id, @schedule_id, @row, @seat, 1, 0, GETDATE())
	END
END

GO
CREATE PROCEDURE sp_sell_ticket--покупка билетов
@row INT,
@seat INT,
@schedule_id INT,
@client_id INT
AS
DECLARE @temp INT 

IF(@row < (SELECT row FROM Halls JOIN Schedule AS s ON s.hall_id = Halls.id WHERE s.id = 1))
BEGIN
	IF(@seat <= (SELECT seat FROM Halls JOIN Schedule AS s ON s.hall_id = Halls.id WHERE s.id = @schedule_id))
	BEGIN	
		INSERT INTO  Orders VALUES
		(@client_id, @schedule_id, @row, @seat, 0, 1, GETDATE())
	END
END

GO
INSERT INTO Movies VALUES
('Interstellar', 180, 'Sci-Fi', 2014, null, 18),
('Inception', 150, 'Sci-Fi', 2010, null, 18),
('Lion King', 120, 'Animation', 1994, null, 18),
('Terminator 2', 120, 'Action', 1991, null, 18),
('Snatch', 100, 'Criminal', 1995, null, 18)

INSERT INTO Clients VALUES
('unregistered', NULL, '2000-01-01')

INSERT INTO Halls VALUES
('зал 1', 120, 12, 10),
('зал 2', 140, 14, 10),
('зал 3 IMAX', 200, 20, 10)

INSERT INTO Schedule VALUES
(1, 1, '29/03/2023 20:00', 300),
(1, 2, '30/03/2023 20:00', 300),
(2, 3, '29/03/2023 18:00', 450),
(3, 2, '29/03/2023 16:00', 200),
(4, 3, '29/03/2023 20:00', 300),
(5, 1, '30/03/2023 20:00', 250)

GO
SELECT * FROM Schedule_FullView

EXEC sp_sell_ticket 3, 4, 1, 1
EXEC sp_sell_ticket 3, 5, 2, 1
EXEC sp_sell_ticket 4, 3, 3, 1
EXEC sp_sell_ticket 4, 4, 2, 1
EXEC sp_sell_ticket 6, 7, 4, 1
EXEC sp_sell_ticket 6, 6, 4, 1

SELECT * FROM ORDERS
EXEC sp_tickets_sold 'Interstellar'
