CREATE TABLE Transactions (
    TransactionID INT PRIMARY KEY,
    AccountNumber INT,
    TransactionType VARCHAR(20),
    Amount DECIMAL(10, 2),
    TransactionDate TIMESTAMP,
    FOREIGN KEY (AccountNumber) REFERENCES Accounts(AccountNumber)
);