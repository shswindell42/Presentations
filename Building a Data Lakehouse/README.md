# Delta Lakehouse

# Abstract
The Data Lake as quickly been adopted as the landing zone of data platforms, but this data is simply imported into a data warehouse for querying via SQL. Is it possible to take the advantages of a data warehouse and combine them with the scalability and flexability of a data lake? Using tools such as Spark, Delta Lake, and Azure Synapse Analytics we will explore building a data lakehouse that can be the foundation of a robust data platform. 

# Outline
1. Evolution of Data Warehousing
    1. Kimball and the Dimensional Model
        - Also Inmon
    2. Data Lake (Staging 2.0)
    3. Data Lakehouse

2. Meta data layer with Delta Lake
    1. What's a delta lake table?
    2. What's the benefit of this?
        - ACID Transactions
        - Schema Evolution
    3. In place Update/Delete/Merge statements

3. ETL with Delta Lake
    - In place Update/Delete/Merge statements

4. Querying Delta Lake
    - Azure Synapse Severless SQL

5. A complete example 
    - Data flowing from source into Lakehouse into Power BI


