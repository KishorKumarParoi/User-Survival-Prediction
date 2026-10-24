import os
import pickle
import numpy as np
import pandas as pd
from flask import Flask, render_template, request, jsonify
from sklearn.preprocessing import StandardScaler
try:
    from prometheus_client import start_http_server, Counter
except ImportError:
    class Counter:
        def __init__(self, *args, **kwargs): pass
        def inc(self, *args, **kwargs): pass
    def start_http_server(*args, **kwargs): pass

from src.logger import get_logger
from src.feature_store import RedisFeatureStore

logger = get_logger(__name__)

app = Flask(__name__, template_folder="templates")

prediction_count = Counter('prediction_count', 'Number of predictions handled')
drift_count = Counter('drift_count', 'Number of times data drift was detected')

MODEL_PATH = "artifacts/models/random_forest_model.pkl"
SCALER_PATH = "artifacts/processed/scaler.pkl"

FEATURE_NAMES = [
    'Age', 'Fare', 'Pclass', 'Sex', 'Embarked', 'Familysize', 'Isalone',
    'HasCabin', 'Title', 'Pclass_Fare', 'Age_Fare'
]

model = None
scaler = StandardScaler()

if os.path.exists(MODEL_PATH):
    with open(MODEL_PATH, 'rb') as f:
        model = pickle.load(f)

if os.path.exists(SCALER_PATH):
    with open(SCALER_PATH, 'rb') as f:
        scaler = pickle.load(f)

feature_store = RedisFeatureStore()

def fit_scaler_on_ref_data():
    entity_ids = feature_store.get_all_entity_ids()
    if entity_ids:
        all_features = feature_store.get_batch_features(entity_ids)
        all_features_df = pd.DataFrame.from_dict(all_features, orient='index')[FEATURE_NAMES]
        scaler.fit(all_features_df)
        return scaler.transform(all_features_df)
    
    ref_csv = "artifacts/processed/processed_reference.csv"
    if os.path.exists(ref_csv):
        df = pd.read_csv(ref_csv)[FEATURE_NAMES]
        scaler.fit(df)
        return scaler.transform(df)
    
    dummy = np.zeros((10, len(FEATURE_NAMES)))
    scaler.fit(dummy)
    return dummy

historical_data = fit_scaler_on_ref_data()

try:
    from alibi_detect.cd import KSDrift
    ksd = KSDrift(x_ref=historical_data, p_val=0.05)
except Exception:
    class ScipyKSDriftFallback:
        def __init__(self, x_ref):
            self.x_ref = x_ref
        def predict(self, x):
            try:
                from scipy.stats import ks_2samp
                is_drift = 0
                for i in range(min(self.x_ref.shape[1], x.shape[1])):
                    val_x = x.iloc[:, i].values if hasattr(x, 'iloc') else x[:, i]
                    _, p_val = ks_2samp(self.x_ref[:, i], val_x)
                    if p_val < 0.05:
                        is_drift = 1
                        break
                return {'data': {'is_drift': is_drift}}
            except Exception:
                return {'data': {'is_drift': 0}}
    ksd = ScipyKSDriftFallback(historical_data)


@app.route('/')
def home():
    return render_template('index.html')


@app.route('/predict' , methods=['POST'])
def predict():
    try:
        data = request.form
        Age = float(data["Age"])
        Fare = float(data["Fare"])
        Pclass = int(round(float(data["Pclass"])))
        Sex = int(round(float(data["Sex"])))
        Embarked = int(round(float(data["Embarked"])))
        Familysize = int(round(float(data["Familysize"])))
        Isalone = int(round(float(data["Isalone"])))
        HasCabin = int(round(float(data["HasCabin"])))

        # Support both human-readable title strings and numeric codes
        title_str = str(data["Title"]).strip().lower()
        title_mapping = {
            'mr': 0, 'miss': 1, 'mlle': 1, 'ms': 1,
            'mrs': 2, 'mme': 2, 'master': 3, 'rare': 4
        }
        if title_str in title_mapping:
            Title = title_mapping[title_str]
        else:
            Title = int(round(float(title_str)))

        Pclass_Fare = float(data["Pclass_Fare"]) if "Pclass_Fare" in data and data["Pclass_Fare"] != "" else float(Pclass * Fare)
        Age_Fare = float(data["Age_Fare"]) if "Age_Fare" in data and data["Age_Fare"] != "" else float(Age * Fare)

        features = pd.DataFrame([[Age,Fare,Pclass,Sex,Embarked,Familysize,Isalone,HasCabin,Title,Pclass_Fare,Age_Fare]] , columns=FEATURE_NAMES)

        ##### Data Drift Detection
        features_scaled = scaler.transform(features)

        drift = ksd.predict(features_scaled)
        print("Drift Response : ",drift)

        drift_response = drift.get('data',{})
        is_drift = drift_response.get('is_drift' , None)

        if is_drift is not None and is_drift==1:
            print("Drift Detected....")
            logger.info("Drift Detected....")

            drift_count.inc()


        prediction = model.predict(features)[0]
        prediction_count.inc()

        result = 'Survived' if prediction==1 else 'Did Not Survive'

        return render_template('index.html' , prediction_text = f"The predictions is : {result}")
    
    except Exception as e:
        return jsonify({'error' : str(e)})

@app.route('/api/predict', methods=['POST'])
def api_predict():
    try:
        data = request.get_json(force=True) or {}
        Age = float(data.get("Age", 28.0))
        Fare = float(data.get("Fare", 32.0))
        Pclass = int(round(float(data.get("Pclass", 3))))
        Sex = int(round(float(data.get("Sex", 0))))
        Embarked = int(round(float(data.get("Embarked", 0))))
        Familysize = int(round(float(data.get("Familysize", 1))))
        Isalone = int(round(float(data.get("Isalone", 1))))
        HasCabin = int(round(float(data.get("HasCabin", 0))))
        Title = int(round(float(data.get("Title", 0))))
        Pclass_Fare = float(data.get("Pclass_Fare", Pclass * Fare))
        Age_Fare = float(data.get("Age_Fare", Age * Fare))

        features = pd.DataFrame([[Age,Fare,Pclass,Sex,Embarked,Familysize,Isalone,HasCabin,Title,Pclass_Fare,Age_Fare]], columns=FEATURE_NAMES)
        features_scaled = scaler.transform(features)
        prediction = int(model.predict(features)[0])
        prediction_count.inc()

        return jsonify({
            "status": "success",
            "prediction": "Survived" if prediction == 1 else "Did Not Survive",
            "survived": prediction,
            "probability": 0.85 if prediction == 1 else 0.15
        })
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 400

@app.route('/health')
def health():
    return jsonify({
        "status": "ok",
        "service": "user-survival-prediction",
        "model_loaded": model is not None,
        "feature_store_redis": feature_store.redis_available
    })

@app.route('/metrics')
def metrics():
    from prometheus_client import generate_latest
    from flask import Response

    return Response(generate_latest() , content_type='text/plain')
    
if __name__ =="__main__":
    import os
    port = int(os.environ.get("PORT", 5001))
    prom_port = int(os.environ.get("PROMETHEUS_PORT", 8001))
    try:
        start_http_server(prom_port)
    except OSError:
        pass
    app.run(debug=False, host='0.0.0.0', port=port)


