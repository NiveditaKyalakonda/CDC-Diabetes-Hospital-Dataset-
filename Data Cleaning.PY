import pandas as pd
import numpy as np

# 1. Load the data (simulated from your SQL export)
df = pd.read_csv("healthcare_data.csv")

# 2. Clean missing data
# Real healthcare data often has missing values marked as '?'
df.replace('?', np.nan, inplace=True)
df['gender'].fillna(df['gender'].mode()[0], inplace=True)

# 3. Simplify the target column (Readmitted)
# We only care if they readmitted within 30 days (1) or not (0)
df['target'] = df['readmitted'].apply(lambda x: 1 if x == '<30' else 0)
df.drop(columns=['readmitted'], inplace=True)

# 4. Convert text categories to numbers (One-Hot Encoding)
df = pd.get_dummies(df, columns=['gender', 'age'], drop_first=True)
