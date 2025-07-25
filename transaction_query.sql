CREATE DATABASE Transactions

select *
from
transactions;


--Checking duplicate value

WITH Duplicate_value  AS
( 
	SELECT *, ROW_NUMBER() OVER (
		PARTITION BY step,type,amount, id_sender, sender_old_balance,
sender_new_balance, id_receiver, receiver_old_balance,
receiver_new_balance, isfraud
	ORDER BY step )AS ROW_NUM
FROM transactions
)
	SELECT * 
	FROM Duplicate_value
WHERE ROW_NUM > 1;

 
 SELECT DISTINCT(type)
 FROM
[dbo].[transactions];

 SELECT type, COUNT(type) AS Count_of_transaction
 FROM
[dbo].[transactions]
GROUP BY type
ORDER BY Count_of_transaction DESC ;

--Average amount by transaction type
SELECT 
    type, 
    AVG(amount) AS average_amount
FROM 
    transactions
GROUP BY 
    type
ORDER BY type DESC;

--Total amount in each transaction type
WITH ROLLINGTOTAL AS
(SELECT type, SUM(amount) AS Roll_total
FROM transactions
GROUP BY type
)
SELECT type, Roll_total, SUM(Roll_total) OVER (ORDER BY type) AS Total_transaction
FROM ROLLINGTOTAL;


--Count of each transaction type
SELECT 
    type, 
    COUNT(*) AS transaction_count
FROM 
    transactions
WHERE 
    type IN ('PAYMENT', 'CASH_OUT', 'CASH_IN', 'TRANSFER', 'DEBIT')
GROUP BY 
    type;


--Rolling total amount by type
WITH TransactionSum AS (
    SELECT 
        type,
        amount,
    SUM(amount) 
	 AS total_amount
FROM  
        transactions
	GROUP BY 
        type,
        amount
)
SELECT 
    type, amount,
   SUM (total_amount) OVER ( ORDER BY type ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS rolling_total
FROM 
    TransactionSum
ORDER BY 
     type, amount;



--AVERAGE AMOUNT BY TRANSACTION TYPE
SELECT 
    type, 
    ROUND(AVG(amount), 2) AS average_amount
FROM 
    transactions
GROUP BY 
    type
ORDER BY average_amount DESC;



--COUNT OF TRANSACTION BY SENDER

WITH SenderTransactionCount AS (
    SELECT 
        id_sender,
        COUNT(*) AS transaction_count,
		type,
        SUM(amount) AS total_volume  
    FROM 
        transactions
    GROUP BY 
        id_sender, type
)
SELECT 
    id_sender,
    transaction_count,
	type,
    total_volume
FROM 
    SenderTransactionCount
ORDER BY 
    transaction_count DESC;

----COUNT OF TRANSACTION BY RECEIVER

WITH ReceiverTransactionCount AS (
    SELECT 
        id_receiver,
        COUNT(*) AS transaction_count,
		type,
        SUM(amount) AS total_volume  
    FROM 
        transactions
    GROUP BY 
        id_receiver, type
)
SELECT 
    id_receiver,
    transaction_count,
	type,
    total_volume
FROM 
    ReceiverTransactionCount
ORDER BY 
    transaction_count DESC;


--COUNT OF TOTAL TRANSACTION BY ISFRAUD
	SELECT type, isFraud,
	COUNT(*) AS transaction_count
	FROM transactions
	WHERE isFraud > 0
	GROUP BY type, isFraud;


--PERCENTAGE OF TRANSACTION BY FRAUD

WITH FraudulentTransactionCount AS (
    SELECT 
        type,
        COUNT(*) AS total_transactions,
        SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END) AS fraudulent_count
    FROM 
        transactions
    GROUP BY 
        type
	)
SELECT 
    type,
    total_transactions,
    fraudulent_count,
    ROUND((CAST(fraudulent_count AS FLOAT) / total_transactions) * 100, 2) AS fraud_percentage
FROM 
    FraudulentTransactionCount
WHERE fraudulent_count > 0;


--specific sender and receiver accounts that show a higher likelihood of fraudulent transactions
WITH TransactionCounts AS (
    SELECT 
        id_sender AS account_id,
		type,
        COUNT(*) AS total_transactions,
        SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END) AS fraudulent_count
    FROM 
        transactions
    GROUP BY 
        id_sender, type
    
    UNION ALL
    
    SELECT 
        id_receiver AS account_id,
		type,
        COUNT(*) AS total_transactions,
        SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END) AS fraudulent_count
    FROM 
        transactions
    GROUP BY 
        id_receiver, type
), 
	AggregatedCounts AS (
    SELECT 
        account_id,
		type,
        SUM(total_transactions) AS total_transactions,
        SUM(fraudulent_count) AS fraudulent_count
    FROM 
        TransactionCounts
    GROUP BY 
        account_id, type
)
SELECT 
    account_id,
	type,
    total_transactions,
    fraudulent_count,
    (CAST(fraudulent_count AS FLOAT) / total_transactions) * 100 AS fraud_percentage
FROM 
    AggregatedCounts
WHERE 
    total_transactions > 0 
	AND fraudulent_count > 0 -- To avoid division by zero
ORDER BY 
    fraud_percentage ;  -- Order by likelihood of fraud



--specific sender or receiver accounts that show a higher likelihood of fraudulent transactions?

WITH SenderFraudulentTransactions AS (
    SELECT 
   id_sender AS account_id,
        type,
        COUNT(*) AS total_transactions,
        SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END) AS fraudulent_count
    FROM 
        transactions
    WHERE 
        isFraud = 1  -- Filter for only fraudulent transactions
    GROUP BY 
        id_sender, type
)
SELECT 
    account_id,
    type,
    total_transactions,
    fraudulent_count,
    (CAST(fraudulent_count AS FLOAT) / total_transactions) * 100 AS fraud_percentage,
    'Sender' AS account_role
FROM 
    SenderFraudulentTransactions
WHERE 
    total_transactions > 0  -- To avoid division by zero
ORDER BY 
    fraud_percentage ;  


WITH ReceiverFraudulentTransactions AS (
    SELECT 
        id_receiver AS account_id,
        type,
        COUNT(*) AS total_transactions,
        SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END) AS fraudulent_count
    FROM 
        transactions
    WHERE 
        isFraud = 1  -- Filter for only fraudulent transactions
    GROUP BY 
        id_receiver, type
)
SELECT 
    account_id,
    type,
    total_transactions,
    fraudulent_count,
    (CAST(fraudulent_count AS FLOAT) / total_transactions) * 100 AS fraud_percentage,
    'Receiver' AS account_role
FROM 
    ReceiverFraudulentTransactions
WHERE 
    total_transactions > 0  -- To avoid division by zero
ORDER BY 
    fraud_percentage DESC;  

