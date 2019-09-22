# OpenFlightsTravel-dataELT
```ruby
1. download "code-part.sql"
2. Open --> File --> /locationofyourfile/code-part.sql. 
```

snowflake Schema: 
For Our snowflake Schema no Hierarchy structure was chosen in order to simplify the schema and create less number of tables. This will subsequently lead to less number of join processing when producing reports from star schema. Also considering that creating hierarchy would require normalised tables versus to un-normalized in Non-hierarchy model and final report from requirements paper did not include drill-down style reports we decided to keep it simple as per requirements.

SCD type 4:
We used SCD type 4 to reflect the discounts history as we noticed that despite that price of membership is stable, however discounts history is changing over time. For the purposes of producing the required reports we needed to keep all the history of discounts over time. Just keeping last and previous was not enough as changes were frequent enough. So the choice was SCD type 4 as the one that reflects all the history of changes. 


**Oracle ERD:**
![SnowFlake](https://user-images.githubusercontent.com/44200835/65380984-b36ada00-dd2a-11e9-80de-d444b18fb9b2.png)








**Oracle tables:**















![All-Tables](https://user-images.githubusercontent.com/44200835/65380985-b960bb00-dd2a-11e9-95de-339d7b554fee.png)
