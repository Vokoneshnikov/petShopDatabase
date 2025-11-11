1. Посчитай, сколько питомцев у каждого клиента, и выведи ТОП‑5 владельцев с наибольшим числом животных.

```
with pet_counts as (
 select 
  c.id, c.name, c.surname, count(p.id) as pet_count
 from client c 
 join pet p on c.id = p.owner_id 
 group by c.id, c.name, c.surname 
)
select * 
from pet_counts
order by pet_count desc 
limit 5;
```
<img width="956" height="274" alt="image" src="https://github.com/user-attachments/assets/d99b2694-5dec-4283-830a-4bab915644ae" />

2. 
3. 
4. 
5. 
6. 
7. 
8. 
9. 
10. 
11. 
12. 
13. 
14. 
15. 
16. 
17. 
18. 
19. 
20. 
21. 
22. 
