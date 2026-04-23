from fastapi import FastAPI
import joblib
import pandas as pd

app = FastAPI()

# 核心修正：指向正确的模型文件夹路径
MODEL_PATH = "05_models/credit_model.pkl"
TRANSFORMER_PATH = "05_models/woe_transformer.pkl"

# 服务启动时加载模型
# 加上文件夹路径 05_models/
model = joblib.load('05_models/credit_model.pkl')
transformer = joblib.load('05_models/woe_transformer.pkl')


@app.post("/predict")
def predict(data: dict):
    # 1. 接收 JSON 数据并转为 DataFrame
    df = pd.DataFrame([data])
    
    # 2. 这里的预处理非常关键，必须把原始数据转成 WOE 才能预测
    # 注意：确保你的 transformer 能够处理单行 DataFrame
    df_woe = transformer.transform(df)
    
    # 3. 使用转换后的数据进行预测
    prob = model.predict_proba(df_woe)[:, 1][0]
    
    # 4. 返回结果
    decision = "Reject" if prob > 0.15 else "Accept"
    
    return {
        "probability": round(float(prob), 4), 
        "decision": decision
    }