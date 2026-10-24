import os
import sys
import json
import logging
import pandas as pd
try:
    import redis
except ImportError:
    redis = None

logger = logging.getLogger(__name__)

class RedisFeatureStore:
    def __init__(self, host=None, port=None, db=0):
        self.host = host or os.environ.get("REDIS_HOST", "localhost")
        self.port = int(port or os.environ.get("REDIS_PORT", 6379))
        self.db = db
        self.memory_store = {}
        self.redis_available = False

        if redis is not None:
            try:
                self.client = redis.StrictRedis(
                    host=self.host,
                    port=self.port,
                    db=self.db,
                    socket_timeout=0.8,
                    decode_responses=True
                )
                self.client.ping()
                self.redis_available = True
                logger.info(f"Connected to Redis Feature Store at {self.host}:{self.port}")
            except Exception as e:
                logger.warning(f"Redis not reachable ({e}). Running in resilient in-memory feature store mode.")
                self.redis_available = False
                self._seed_reference_data()
        else:
            logger.info("Redis library not installed. Running in resilient in-memory feature store mode.")
            self.redis_available = False
            self._seed_reference_data()

    def _seed_reference_data(self):
        """Seed initial reference data from CSV if Redis is not running."""
        ref_path = "artifacts/processed/processed_reference.csv"
        if os.path.exists(ref_path):
            try:
                df = pd.read_csv(ref_path)
                for idx, row in df.iterrows():
                    self.memory_store[f"entity:{idx}:features"] = row.to_dict()
                logger.info(f"Seeded {len(self.memory_store)} reference entities into in-memory store.")
            except Exception as e:
                logger.error(f"Failed to seed reference data: {e}")

    def store_features(self, entity_id, features):
        key = f"entity:{entity_id}:features"
        if self.redis_available:
            try:
                self.client.set(key, json.dumps(features))
                return
            except Exception:
                self.redis_available = False
        self.memory_store[key] = features

    def get_features(self, entity_id):
        key = f"entity:{entity_id}:features"
        if self.redis_available:
            try:
                val = self.client.get(key)
                if val:
                    return json.loads(val)
            except Exception:
                self.redis_available = False
        return self.memory_store.get(key)

    def store_batch_features(self, batch_data):
        for entity_id, features in batch_data.items():
            self.store_features(entity_id, features)

    def get_batch_features(self, entity_ids):
        batch_features = {}
        for entity_id in entity_ids:
            batch_features[entity_id] = self.get_features(entity_id)
        return batch_features

    def get_all_entity_ids(self):
        if self.redis_available:
            try:
                keys = self.client.keys("entity:*:features")
                if keys:
                    return [k.split(":")[1] for k in keys]
            except Exception:
                self.redis_available = False
        return [k.split(":")[1] for k in self.memory_store.keys()]
