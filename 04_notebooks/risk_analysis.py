import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns


# 1. 读取你导出的 CSV 文件
df = pd.read_csv('../03_clean_data/cleaned_data_202604.csv.csv')

# 假设你的数据叫 df，目标变量列名是 'SeriousDlqin2yrs'
target = 'SeriousDlqin2yrs'


quality = toad,quality(df, target=target)
