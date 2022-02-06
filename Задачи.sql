/*Радюш Дарья и Пузевич Роман*/
/*1. По каждой книге посчитать стоимость заказанного, проданного и отгруженного по месяцам в 2021 году. Выводить всё в одном селекте.*/
SELECT (SELECT Book FROM Books as B WHERE B.Book_ID = Orders_data.Book_ID) as Book, MONTH(Orders.Date_of_Order) as Month, 
	   SUM(Orders_data.Qty_ord*Orders_data.Price_RUR) as Order_sum,
	   SUM(case when Sum_RUR = Pmnt_RUR then Qty_out*Price_RUR else 0 end) as Buy_sum,
	   SUM(Orders_data.Qty_out*Orders_data.Price_RUR) as Out_sum
FROM Orders inner join Orders_data on Orders.ndoc = Orders_data.ndoc
WHERE YEAR(Orders.Date_of_Order) = 2021
GROUP BY Orders_data.Book_ID, MONTH(Orders.Date_of_Order)

/*2. По каждому разделу посчитать среднюю стоимость заказанного товара в день за последний месяц. 
Учитывать и те дни, когда ни одна книга из данного раздела заказана не была, но были заказаны книги из каких-либо других разделов,
но не учитывать те дни, когда книги не заказывались вообще. 
Средняя стоимость = суммарная стоимость/колво дней.*/
SELECT Section, (case when T.Sum is Null then 0 
	   else T.Sum/(select COUNT(distinct DAY(Date_of_Order)) FROM Orders WHERE Date_of_Order between dateadd(month, -1, getdate()) and getdate()) end) as Average_sum 
FROM Sections left join 
(SELECT Books.Section_ID as S, SUM(Qty_ord*Orders_data.Price_RUR) as Sum
FROM (Orders_data inner join Books on Orders_data.Book_ID = Books.Book_ID) inner join Orders on Orders.ndoc = Orders_data.ndoc
where Orders.Date_of_Order between dateadd(month, -1, getdate()) and getdate()
group by Books.Section_ID) as T on Sections.Section_ID = T.S

/*3.	По каждому автору вывести его рейтинг за последний месяц. 
У автора с максимальной суммарной стоимостью заказанного рейтинг = 1, у второго по суммарной стоимости заказанного рейтинг = 2 и тд. 
В случае если существует несколько авторов с одинаковой стоимостью, рейтинг по каждому равен максимальному для них возможному. 
Например, суммарная стоимость по 1-ому автору = 100, по двум следующим 50, рейтинг 1-ого равен единице, рейтинги 2-ого и 3-его равны трем.*/
SELECT (SELECT Surname + ' ' + Name FROM Authors where Books.Author_ID = Authors.Author_ID) as Author
FROM (Orders_data inner join Books on Orders_data.Book_ID = Books.Book_ID) inner join Orders on Orders.ndoc = Orders_data.ndoc
where Orders.Date_of_Order between dateadd(month, -1, getdate()) and dateadd(day, -1, getdate())
group by Books.Author_ID
order by SUM(Orders_data.Qty_ord*Orders_data.Price_RUR) desc
/*тут вообще не выводит рейтинг, просто отсортированные по сумме продаж Авторы*/

/*4. Вывести по каждому покупателю (включая тех, кто не делал заказы) суммарный оборот за последний месяц. 
Оборот = суммарная стоимость оплаченного. Для тех, кто заказы не делал, выводить 0.*/
SELECT Customer, (case when T.Pmnt is null then 0 else T.Pmnt end) as Oborot
FROM Customers left join
(SELECT Cust_ID as C, SUM(Pmnt_RUR) as Pmnt
FROM Orders
where Date_of_Order between dateadd(month, -1, getdate()) and dateadd(day, -1, getdate())
group by Cust_ID) as T on Customers.Cust_ID = T.C 

/*5. Вывести книги, которые есть в остатке на складе на сейчас, но их не ставили в заказ после 01.10.21.*/
SELECT Book
FROM Books inner join Stock on Books.Book_ID = Stock.Book_ID
where Stock.Qty_in_Stock - Stock.Qty_rsrv > 0
	except
SELECT Book
FROM Books left join Orders_data on Books.Book_ID = Orders_data.Book_ID
	 inner join Orders on Orders.ndoc = Orders_data.ndoc
	 inner join Stock on Orders_data.Book_ID = Stock.Book_ID 
where Stock.Qty_in_Stock - Stock.Qty_rsrv > 0 and Orders.Date_of_Order > '20211001'

/*6. Вывести покупателя и такие его книги, что покупатель заказывал эти книги до 01.10.21, 
но не заказывал после 01.10.21, при этом эти книги есть в наличии (остаток > 0)*/
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

/*7. Вывести долю товара в резерве (доля в стоимости и доля от штук) от суммарного физического остатка на текущий момент. Цена – по текущей цене книги.*/
/*К сожалению, не сделали проверку*/
SELECT SUM(Qty_rsrv)/SUM(Qty_in_Stock) as Dolprice, SUM(Qty_rsrv*Price_RUR)/SUM(Qty_in_Stock*Price_RUR) as Dolkolvo
FROM Books inner join Stock on Stock.Book_ID = Books.Book_ID

/*8. Вывести покупателей, которые забрали книги, но не оплатили заказ, и тех, которые оплатили заказ, но книги не забрали. 
Для таких покупателей кроме названия вывести: 1) стоимость отпущенных книг, за которые не заплатили, 2) суммарную оплату за книги, 
которые они еще не забрали. Вывод должен быть в одном рекордсете с дополнительным комментарием, позволяющим отделить один тип покупателей от другого*/
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

/*9. По коду книги, количеству, покупателю_ID показывать, возможен ли заказ этого товара с указанным количеством. 
Код книги, колво, код покупателя передаются параметрами. Запрос должен возвращать 0, если не возможен, иначе 1. 
(то есть покупатель хочет заказать определенную книгу, мы должны сказать, может он это сделать или нет. Подумайте, в каком случае «нет»).*/
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

/*10. Написать запрос, который по номеру документа проставляет итоговое значение Sum_RUR в Orders, равное суммарной стоимости всех книг в Orders_data.*/
update Orders
set Sum_RUR = (SELECT SUM(Price_RUR*Qty_ord)
			   FROM Orders_data
			   where Orders.ndoc = Orders_data.ndoc
			   group by ndoc)
			   
/*11. По номеру заказа определять, можно ли полностью оплатить его из баланса покупателя. Запрос должен возвращать 1 – если можно, 0 – иначе*/
declare @ndoc1 int
set @ndoc1 = 10

SELECT
(case
when (SELECT Balance FROM Customers where Cust_ID = (SELECT Cust_ID FROM Orders where ndoc = @ndoc1)) >= (SELECT Sum_RUR FROM Orders where ndoc = @ndoc1)
then 1
else 0
end) as Result

/*12. Написать запрос, который по номеру заказа проставляет оплату в заказе (если это можно сделать) и обновляет баланс покупателя. 
Желательно в одном предложении (чтобы в случае ошибки автоматически откатывались обе транзакции), но можно сделать и разными запросами.*/
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

/*13. Написать запрос, который по заданному номеру заказа изменяет поле «Qty_rsrv» в остатках по каждому товару из заказа на величину заказанного. 
(То есть запрос, который по заказу резервирует товар, чтобы количество, которое заказал наш покупатель, не было доступно для заказа другим покупателям, 
но не забываем, что товар покупатель еще со склада не забрал). Не забывайте, что в одном заказе одна книга может встречаться в разных строках, проверьте, 
что Ваш запрос работает правильно.*/
declare @ndoc3 int
set @ndoc3 = 10

update Stock
set Qty_rsrv = Qty_rsrv + (SELECT SUM(Qty_ord)
						   FROM Orders_data
						   where ndoc = @ndoc3 and Orders_data.Book_ID = Stock.Book_ID 
						   group by Book_ID)
						   
/*14. Написать запрос, который по заданному номеру заказа изменяет поле «Qty_in_stock» в остатках по каждой книге из заказа 
на величину отпущенного, а также соответствующим образом изменяет поле «Qty_rsrv». 
(То есть покупатель забирает зарезервированный товар со склада, что при этом должно произойти с остатками этого товара на складе?)*/
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



