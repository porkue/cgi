delimiter //
create procedure stockdown ()
begin
   select * from simple where cap > 20 and close > 2 and date = (select max(date) from simple)  order by change_pct  limit 50 ;
end //

delimiter ;   
