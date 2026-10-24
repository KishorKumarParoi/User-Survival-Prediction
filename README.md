# 🚢 User Survival Prediction & MLOps Infrastructure Platform

[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker&logoColor=white)](Dockerfile)
[![Python](https://img.shields.io/badge/Python-3.11-3776AB?style=for-the-badge&logo=python&logoColor=white)](requirements.txt)
[![Redis](https://img.shields.io/badge/Redis-Feature%20Store-DC382D?style=for-the-badge&logo=redis&logoColor=white)](src/feature_store.py)
[![Prometheus](https://img.shields.io/badge/Prometheus-Telemetry-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)](prometheus.yml)
[![Grafana](https://img.shields.io/badge/Grafana-Monitoring-F46800?style=for-the-badge&logo=grafana&logoColor=white)](docker-compose.yml)

An enterprise-grade, end-to-end Machine Learning Operations (MLOps) platform demonstrating production survival classification, **Redis Low-Latency Feature Store**, **Astro Airflow** ETL orchestration, **Alibi Detect Kolmogorov-Smirnov** statistical drift telemetry, **Prometheus** observability, and **Flask** serving.

---

## 🚀 One-Click Instant Cloud Deployment (Zero-Touch)

Deploy the entire production stack (Redis, Prediction Engine, Prometheus, and Grafana) on any fresh Ubuntu/Debian/Amazon Linux EC2 instance or local machine with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/KishorKumarParoi/User-Survival-Prediction/main/bootstrap.sh | bash
```

> **Automated Under the Hood:**
> - Non-interactive package setup & 4GB Swapfile creation (OOM protection on small VMs).
> - Automated Docker Engine & Compose installation.
> - High-speed shallow repository clone (`--depth 1`).
> - Multi-container startup with automated health probes.

---

## 🏛️ System Architecture Flow

![Architecture Flow](docs/images/01_architecture_flow.svg)

```
+--------------------------------------------------------------------------------------------------+
|                                  USER SURVIVAL MLOPS PLATFORM                                    |
+--------------------------------------------------------------------------------------------------+
|  [ Data Ingestion ]: Astro Airflow DAGs (dags/) orchestrating automated batch feature extraction |
|          |                                                                                       |
|          v                                                                                       |
|  [ Feature Store ]: Redis Low-Latency Caching (entity:id:features) with In-Memory Fallback       |
|          |                                                                                       |
|          v                                                                                       |
|  [ Inference Engine ]: Optimized Random Forest Classifier (88.9% Holdout Accuracy)               |
|          |                                                                                       |
|          +---> [ KS-Drift Detector ]: Alibi Detect Kolmogorov-Smirnov 2-sample statistical test   |
|          |                                                                                       |
|          v                                                                                       |
|  [ API & Serving ]: Flask UI (:5001) + REST API (/api/predict) + Health Probe (/health)          |
|          |                                                                                       |
|          v                                                                                       |
|  [ Telemetry ]: Prometheus (/metrics on :8001 & :9090) -> Grafana Real-Time AI Dashboard (:3000) |
+--------------------------------------------------------------------------------------------------+
```

Detailed architectural specifications, data contracts, and SLO designs are documented in **[`ARCHITECTURE.md`](ARCHITECTURE.md)**.

---

## 🌟 Key Architecture Pillars

1. **Airflow Orchestration**: Fully automated DAGs under Astro Airflow (`airflow_settings.yaml`, `dags/`) orchestrating automated periodic batch feature extraction.
2. **Redis Low-Latency Feature Store**: Sub-2ms real-time feature retrieval eliminating offline-online skew, with automated in-memory fallback.
3. **Kolmogorov-Smirnov Covariate Drift Detection**: Continuous distribution comparison with Alibi Detect triggering real-time Prometheus alerts upon data drift.
4. **Live Prometheus & Grafana Telemetry**: Scrapes inference counts, latency histograms, and drift flags.
5. **Interactive Glassmorphic UI & REST API**: High-fidelity web interface and clean RESTful endpoint (`/api/predict`).

---

## 📁 Repository Structure

```
.
├── config/                      # Pipeline schema, parameters, and database config
├── dags/                        # Astro Airflow DAG definitions for automated ETL
├── src/
│   ├── components/              # Data ingestion and model trainer components
│   ├── feature_store.py         # Resilient Redis Feature Store with memory fallback
│   ├── data_processing.py       # Feature engineering & scaling transformations
│   ├── model_training.py        # Model evaluation & Random Forest training
│   ├── custom_exception.py      # Traceback-preserving custom exception handler
│   └── logger.py                # Structured production logging
├── artifacts/
│   ├── models/                  # Serialized trained model (random_forest_model.pkl)
│   ├── processed/               # Fitted StandardScalers & reference datasets
│   └── raw/                     # Train and test split datasets
├── templates/                   # Glassmorphic user interface templates
├── static/                      # Styling and frontend assets
├── docs/images/                 # High-resolution architectural flow diagrams
├── bootstrap.sh                 # Zero-touch 1-command cloud bootstrapper
├── deploy.sh                    # Multi-mode production deployment launcher
├── clear.sh                     # Idempotent $0.00 zero-cost teardown script
├── ARCHITECTURE.md              # In-depth architectural design specification
├── prometheus.yml               # Prometheus telemetry scrape configuration
├── docker-compose.yml           # Production Redis + Web + Prometheus + Grafana stack
├── Dockerfile                   # Containerized runtime image
└── main.py                      # Production web application & REST API
```

---

## 🛠️ Local & Manual Deployment Options

### Option 1: Standard Docker Compose (Recommended)
```bash
./deploy.sh
```
Launches Redis, Web (:5001), Prometheus (:9090), and Grafana (:3000).

### Option 2: Lightweight Single-Container Mode
```bash
./deploy.sh --quick
```

### Option 3: Host Execution
```bash
./deploy.sh --host
```

---

## 🧹 $0.00 Teardown
Restore clean compute state and eliminate all running resources:
```bash
./clear.sh
```

---

## 👤 Author
**Kishor Kumar Paroi**  
- **GitHub:** [@KishorKumarParoi](https://github.com/KishorKumarParoi)  
- **Portfolio:** [macos-portfolio](https://macos-portofolio-virid.vercel.app/)
