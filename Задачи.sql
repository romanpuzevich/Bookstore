/*����� ����� � ������� �����*/
/*1. �� ������ ����� ��������� ��������� �����������, ���������� � ������������ �� ������� � 2021 ����. �������� �� � ����� �������.*/
SELECT (SELECT Book FROM Books as B WHERE B.Book_ID = Orders_data.Book_ID) as Book, MONTH(Orders.Date_of_Order) as Month, 
	   SUM(Orders_data.Qty_ord*Orders_data.Price_RUR) as Order_sum,
	   SUM(case when Sum_RUR = Pmnt_RUR then Qty_out*Price_RUR else 0 end) as Buy_sum,
	   SUM(Orders_data.Qty_out*Orders_data.Price_RUR) as Out_sum
FROM Orders inner join Orders_data on Orders.ndoc = Orders_data.ndoc
WHERE YEAR(Orders.Date_of_Order) = 2021
GROUP BY Orders_data.Book_ID, MONTH(Orders.Date_of_Order)

/*2. �� ������� ������� ��������� ������� ��������� ����������� ������ � ���� �� ��������� �����. 
��������� � �� ���, ����� �� ���� ����� �� ������� ������� �������� �� ����, �� ���� �������� ����� �� �����-���� ������ ��������,
�� �� ��������� �� ���, ����� ����� �� ������������ ������. 
������� ��������� = ��������� ���������/����� ����.*/
SELECT Section, (case when T.Sum is Null then 0 
	   else T.Sum/(select COUNT(distinct DAY(Date_of_Order)) FROM Orders WHERE Date_of_Order between dateadd(month, -1, getdate()) and getdate()) end) as Average_sum 
FROM Sections left join 
(SELECT Books.Section_ID as S, SUM(Qty_ord*Orders_data.Price_RUR) as Sum
FROM (Orders_data inner join Books on Orders_data.Book_ID = Books.Book_ID) inner join Orders on Orders.ndoc = Orders_data.ndoc
where Orders.Date_of_Order between dateadd(month, -1, getdate()) and getdate()
group by Books.Section_ID) as T on Sections.Section_ID = T.S

/*3.	�� ������� ������ ������� ��� ������� �� ��������� �����. 
� ������ � ������������ ��������� ���������� ����������� ������� = 1, � ������� �� ��������� ��������� ����������� ������� = 2 � ��. 
� ������ ���� ���������� ��������� ������� � ���������� ����������, ������� �� ������� ����� ������������� ��� ��� ����������. 
��������, ��������� ��������� �� 1-��� ������ = 100, �� ���� ��������� 50, ������� 1-��� ����� �������, �������� 2-��� � 3-��� ����� ����.*/
SELECT (SELECT Surname + ' ' + Name FROM Authors where Books.Author_ID = Authors.Author_ID) as Author
FROM (Orders_data inner join Books on Orders_data.Book_ID = Books.Book_ID) inner join Orders on Orders.ndoc = Orders_data.ndoc
where Orders.Date_of_Order between dateadd(month, -1, getdate()) and dateadd(day, -1, getdate())
group by Books.Author_ID
order by SUM(Orders_data.Qty_ord*Orders_data.Price_RUR) desc
/*��� ������ �� ������� �������, ������ ��������������� �� ����� ������ ������*/

/*4. ������� �� ������� ���������� (������� ���, ��� �� ����� ������) ��������� ������ �� ��������� �����. 
������ = ��������� ��������� �����������. ��� ���, ��� ������ �� �����, �������� 0.*/
SELECT Customer, (case when T.Pmnt is null then 0 else T.Pmnt end) as Oborot
FROM Customers left join
(SELECT Cust_ID as C, SUM(Pmnt_RUR) as Pmnt
FROM Orders
where Date_of_Order between dateadd(month, -1, getdate()) and dateadd(day, -1, getdate())
group by Cust_ID) as T on Customers.Cust_ID = T.C 

/*5. ������� �����, ������� ���� � ������� �� ������ �� ������, �� �� �� ������� � ����� ����� 01.10.21.*/
SELECT Book
FROM Books inner join Stock on Books.Book_ID = Stock.Book_ID
where Stock.Qty_in_Stock - Stock.Qty_rsrv > 0
	except
SELECT Book
FROM Books left join Orders_data on Books.Book_ID = Orders_data.Book_ID
	 inner join Orders on Orders.ndoc = Orders_data.ndoc
	 inner join Stock on Orders_data.Book_ID = Stock.Book_ID 
where Stock.Qty_in_Stock - Stock.Qty_rsrv > 0 and Orders.Date_of_Order > '20211001'

/*6. ������� ���������� � ����� ��� �����, ��� ���������� ��������� ��� ����� �� 01.10.21, 
�� �� ��������� ����� 01.10.21, ��� ���� ��� ����� ���� � ������� (������� > 0)*/
SELECT Customer, Book
FROM Books inner join Orders_data on Books.Book_ID = Orders_data.Book_ID 
	 inner join Orders on Orders.ndoc = Orders_data.ndoc
	 inner join Customers on Orders.Cust_ID = Customers.Cust_ID
	 inner join Stock on Stock.Book_ID = Books.Book_ID
where Stock.Qty_in_Stock - Stock.Qty_rsrv > 0 and Orders.Date_of_Order < '20211001'
	except 
SELECT Customer, Book
FROM Books inner join Orders_data on Books.Book_ID = Orders_data.Book_ID 
	 inner join Orders on Orders.ndoc = Orders_data.ndoc
	 inner join Customers on Orders.Cust_ID = Customers.Cust_ID
	 inner join Stock on Stock.Book_ID = Books.Book_ID
where Stock.Qty_in_Stock - Stock.Qty_rsrv > 0 and Orders.Date_of_Order >= '20211001'

/*7. ������� ���� ������ � ������� (���� � ��������� � ���� �� ����) �� ���������� ����������� ������� �� ������� ������. ���� � �� ������� ���� �����.*/
/*� ���������, �� ������� ��������*/
SELECT SUM(Qty_rsrv)/SUM(Qty_in_Stock) as Dolprice, SUM(Qty_rsrv*Price_RUR)/SUM(Qty_in_Stock*Price_RUR) as Dolkolvo
FROM Books inner join Stock on Stock.Book_ID = Books.Book_ID

/*8. ������� �����������, ������� ������� �����, �� �� �������� �����, � ���, ������� �������� �����, �� ����� �� �������. 
��� ����� ����������� ����� �������� �������: 1) ��������� ���������� ����, �� ������� �� ���������, 2) ��������� ������ �� �����, 
������� ��� ��� �� �������. ����� ������ ���� � ����� ���������� � �������������� ������������, ����������� �������� ���� ��� ����������� �� �������*/
SELECT (SELECT Customer FROM Customers where Orders.Cust_ID = Customers.Cust_ID) as Customer,
	   ((SELECT Book FROM Books where Books.Book_ID = Orders_data.Book_ID) + ' (Not taken)') as Book, 
	   Qty_ord*Price_RUR as Price
FROM Orders inner join Orders_data on Orders.ndoc = Orders_data.ndoc
where Qty_ord != Qty_out and Sum_RUR = Pmnt_RUR
	union
SELECT (SELECT Customer FROM Customers where Orders.Cust_ID = Customers.Cust_ID),
	   ((SELECT Book FROM Books where Books.Book_ID = Orders_data.Book_ID) + ' (Not taken)') as Book, 
	   Qty_ord*Price_RUR as Price
FROM Orders inner join Orders_data on Orders.ndoc = Orders_data.ndoc
where Qty_ord = Qty_out and Sum_RUR != Pmnt_RUR

/*9. �� ���� �����, ����������, ����������_ID ����������, �������� �� ����� ����� ������ � ��������� �����������. 
��� �����, �����, ��� ���������� ���������� �����������. ������ ������ ���������� 0, ���� �� ��������, ����� 1. 
(�� ���� ���������� ����� �������� ������������ �����, �� ������ �������, ����� �� ��� ������� ��� ���. ���������, � ����� ������ ����).*/
declare @book_id1 int, @count_of_books1 int, @cust_id1 int
set @book_id1 = 1
set @count_of_books1 = 10
set @cust_id1 = 4

SELECT 
(case 
when (SELECT Balance FROM Customers where Cust_ID = @cust_id1)*0.1 >= @count_of_books1*(SELECT Price_RUR FROM Books where Book_ID = @book_id1) 
then 1
else 0
end) as Result

/*10. �������� ������, ������� �� ������ ��������� ����������� �������� �������� Sum_RUR � Orders, ������ ��������� ��������� ���� ���� � Orders_data.*/
update Orders
set Sum_RUR = (SELECT SUM(Price_RUR*Qty_ord)
			   FROM Orders_data
			   where Orders.ndoc = Orders_data.ndoc
			   group by ndoc)
			   
/*11. �� ������ ������ ����������, ����� �� ��������� �������� ��� �� ������� ����������. ������ ������ ���������� 1 � ���� �����, 0 � �����*/
declare @ndoc1 int
set @ndoc1 = 10

SELECT
(case
when (SELECT Balance FROM Customers where Cust_ID = (SELECT Cust_ID FROM Orders where ndoc = @ndoc1)) >= (SELECT Sum_RUR FROM Orders where ndoc = @ndoc1)
then 1
else 0
end) as Result

/*12. �������� ������, ������� �� ������ ������ ����������� ������ � ������ (���� ��� ����� �������) � ��������� ������ ����������. 
���������� � ����� ����������� (����� � ������ ������ ������������� ������������ ��� ����������), �� ����� ������� � ������� ���������.*/
declare @ndoc2 int
set @ndoc2 = 4

update Orders
set Pmnt_RUR = (SELECT (case
						when (SELECT Balance FROM Customers where Orders.Cust_ID = Customers.Cust_ID) >= Sum_RUR 
						then Sum_RUR
						else 0 end)
				FROM Orders
				where @ndoc2 = ndoc)
where Orders.ndoc = @ndoc2

update Customers
set Balance = Balance - (SELECT (case
								when Balance >= (SELECT Sum_RUR FROM Orders where ndoc = @ndoc2)
								then (SELECT Sum_RUR FROM Orders where ndoc = @ndoc2)
								else 0 end))

/*13. �������� ������, ������� �� ��������� ������ ������ �������� ���� �Qty_rsrv� � �������� �� ������� ������ �� ������ �� �������� �����������. 
(�� ���� ������, ������� �� ������ ����������� �����, ����� ����������, ������� ������� ��� ����������, �� ���� �������� ��� ������ ������ �����������, 
�� �� ��������, ��� ����� ���������� ��� �� ������ �� ������). �� ���������, ��� � ����� ������ ���� ����� ����� ����������� � ������ �������, ���������, 
��� ��� ������ �������� ���������.*/
declare @ndoc3 int
set @ndoc3 = 10

update Stock
set Qty_rsrv = Qty_rsrv + (SELECT SUM(Qty_ord)
						   FROM Orders_data
						   where ndoc = @ndoc3 and Orders_data.Book_ID = Stock.Book_ID 
						   group by Book_ID)
						   
/*14. �������� ������, ������� �� ��������� ������ ������ �������� ���� �Qty_in_stock� � �������� �� ������ ����� �� ������ 
�� �������� �����������, � ����� ��������������� ������� �������� ���� �Qty_rsrv�. 
(�� ���� ���������� �������� ����������������� ����� �� ������, ��� ��� ���� ������ ��������� � ��������� ����� ������ �� ������?)*/
declare @ndoc4 int
set @ndoc4 = 5

update Stock 
set Qty_in_Stock = Qty_in_Stock - OD.Sum
FROM Stock inner join 
(SELECT Book_ID as BI, SUM(Qty_ord) as Sum
FROM Orders_data
where ndoc = @ndoc4
group by Book_ID) as OD on Stock.Book_ID = OD.BI

update Stock 
set Qty_rsrv = Qty_rsrv - OD.Sum
FROM Stock inner join 
(SELECT Book_ID as BI, SUM(Qty_ord) as Sum
FROM Orders_data
where ndoc = @ndoc4
group by Book_ID) as OD on Stock.Book_ID = OD.BI



