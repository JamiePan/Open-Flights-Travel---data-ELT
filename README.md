# OpenFlightsTravel-dataELT
```ruby
1. download "code-part.sql"
2. Open --> File --> /locationofyourfile/code-part.sql. 
```

**Snowflake Schema:**
For Our snowflake Schema no Hierarchy structure was chosen in order to simplify the schema and create less number of tables. This will subsequently lead to less number of join processing when producing reports from star schema. Also considering that creating hierarchy would require normalised tables versus to un-normalized in Non-hierarchy model and final report from requirements paper did not include drill-down style reports we decided to keep it simple as per requirements.

**SCD type 4:**
We used SCD type 4 to reflect the discounts history as we noticed that despite that price of membership is stable, however discounts history is changing over time. For the purposes of producing the required reports we needed to keep all the history of discounts over time. Just keeping last and previous was not enough as changes were frequent enough. So the choice was SCD type 4 as the one that reflects all the history of changes. 

**Expected Output:**
**- Average Total Paid for tickets**
**- Average Agent Profit (total paid – flight fare)**
**- Average Passenger Age**
**- Total Number of Routes**
**- Average Route Distance**
**- Total Service Cost**
**- Average Membership Sales**


**Oracle ERD:**
![SnowFlake](https://user-images.githubusercontent.com/44200835/65380984-b36ada00-dd2a-11e9-80de-d444b18fb9b2.png)








**Oracle tables:**















![All-Tables](https://user-images.githubusercontent.com/44200835/65380985-b960bb00-dd2a-11e9-95de-339d7b554fee.png)






***Report***

**- Report 1:
What is the top 3 average ages of passengers traveling on business class from an Australian airport?** 

![report1](https://user-images.githubusercontent.com/44200835/65381162-13637f80-dd2f-11e9-8d53-b1ff8212b606.png)



**- Report 2:
What is the total number of newly joined gold membership for Adults passenger in each month?** 

![report2](https://user-images.githubusercontent.com/44200835/65381164-16f70680-dd2f-11e9-8964-91c255646771.png)



**- Report 3:
Generate a flight report for different dimensions, which refers 'Number of Transactions' and 'Average Agent Profit' for 'GROUP' OF ALL ANY COLUMNS.** 

![report3](https://user-images.githubusercontent.com/44200835/65381165-19596080-dd2f-11e9-8de4-1ba02b1534c0.png)

**Query Trees & Execution Times:**
![report3_explain](https://user-images.githubusercontent.com/44200835/65381258-e7e19480-dd30-11e9-8d2a-c9cfa06ba1cc.png)




**- Report 4:
What are the sub-total and total agent profits of airports and airlines? ('CUBE' operator)** 

![report4](https://user-images.githubusercontent.com/44200835/65381166-1b232400-dd2f-11e9-8ecb-0d7058a4a6ac.png)

**Query Trees & Execution Times:**
![report4_explain](https://user-images.githubusercontent.com/44200835/65381260-e87a2b00-dd30-11e9-9061-9580164de488.png)




**- Report 5:
What are the total and cumulative monthly total sales of Gold membership in 2009?** 

![report5](https://user-images.githubusercontent.com/44200835/65381167-1e1e1480-dd2f-11e9-81a6-db378a0c9e76.png)

**Query Trees & Execution Times:**
![report5_explain](https://user-images.githubusercontent.com/44200835/65381272-0e9fcb00-dd31-11e9-9c0e-9b93e73c8a8f.png)




**- Report 6:
What are the city ranks by total number of incoming routes in each country?** 

![report6](https://user-images.githubusercontent.com/44200835/65381169-1fe7d800-dd2f-11e9-8a9d-6970a5b3d49a.png)

**Query Trees & Execution Times:**
![report6_explain](https://user-images.githubusercontent.com/44200835/65381261-eadc8500-dd30-11e9-9aa0-0b639667311d.png)



