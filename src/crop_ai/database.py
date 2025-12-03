"""
Database integration for crop-ai predictions.
"""
import logging
from datetime import datetime
from dataclasses import dataclass
from typing import Optional, List
import json

logger = logging.getLogger(__name__)

@dataclass
class PredictionRecord:
    """Record of a prediction."""
    id: Optional[str] = None
    image_url: str = ""
    crop_type: str = ""
    confidence: float = 0.0
    model_version: str = "latest"
    timestamp: str = ""
    processing_time_ms: float = 0.0

class DatabaseAdapter:
    """
    Database adapter for storing predictions.
    Supports multiple backends: PostgreSQL, CosmosDB, SQLite.
    """
    
    def __init__(self, connection_string: Optional[str] = None, db_type: str = "sqlite"):
        """
        Initialize database adapter.
        
        Args:
            connection_string: Database connection string
            db_type: Type of database (sqlite, postgresql, cosmosdb)
        """
        self.db_type = db_type
        self.connection_string = connection_string or "predictions.db"
        self.connected = False
        
        try:
            self._initialize()
            self.connected = True
            logger.info(f"Database adapter initialized: {db_type}")
        except Exception as e:
            logger.warning(f"Failed to initialize database: {e}")
            self.connected = False
    
    def _initialize(self):
        """Initialize database connection."""
        if self.db_type == "sqlite":
            import sqlite3
            self.conn = sqlite3.connect(self.connection_string)
            self._create_sqlite_tables()
        elif self.db_type == "postgresql":
            import psycopg2
            self.conn = psycopg2.connect(self.connection_string)
            self._create_postgres_tables()
        else:
            logger.warning(f"Unsupported database type: {self.db_type}")
    
    def _create_sqlite_tables(self):
        """Create SQLite tables."""
        cursor = self.conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS predictions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                image_url TEXT NOT NULL,
                crop_type TEXT NOT NULL,
                confidence REAL NOT NULL,
                model_version TEXT,
                timestamp TEXT,
                processing_time_ms REAL
            )
        """)
        self.conn.commit()
    
    def _create_postgres_tables(self):
        """Create PostgreSQL tables."""
        cursor = self.conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS predictions (
                id SERIAL PRIMARY KEY,
                image_url TEXT NOT NULL,
                crop_type TEXT NOT NULL,
                confidence REAL NOT NULL,
                model_version TEXT,
                timestamp TEXT,
                processing_time_ms REAL
            )
        """)
        self.conn.commit()
    
    async def save_prediction(self, record: PredictionRecord) -> bool:
        """
        Save a prediction record.
        
        Args:
            record: PredictionRecord to save
            
        Returns:
            True if saved successfully, False otherwise
        """
        if not self.connected:
            logger.warning("Database not connected, skipping save")
            return False
        
        try:
            if self.db_type in ["sqlite", "postgresql"]:
                cursor = self.conn.cursor()
                cursor.execute("""
                    INSERT INTO predictions 
                    (image_url, crop_type, confidence, model_version, timestamp, processing_time_ms)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (
                    record.image_url,
                    record.crop_type,
                    record.confidence,
                    record.model_version,
                    record.timestamp,
                    record.processing_time_ms
                ))
                self.conn.commit()
                logger.info(f"Prediction saved: {record.crop_type} ({record.confidence:.2%})")
                return True
        except Exception as e:
            logger.error(f"Failed to save prediction: {e}")
            return False
    
    async def get_predictions(self, limit: int = 100) -> List[PredictionRecord]:
        """
        Get recent predictions.
        
        Args:
            limit: Maximum number of records to return
            
        Returns:
            List of PredictionRecord objects
        """
        if not self.connected:
            return []
        
        try:
            if self.db_type in ["sqlite", "postgresql"]:
                cursor = self.conn.cursor()
                cursor.execute("""
                    SELECT id, image_url, crop_type, confidence, model_version, timestamp, processing_time_ms
                    FROM predictions
                    ORDER BY timestamp DESC
                    LIMIT %s
                """, (limit,))
                
                records = []
                for row in cursor.fetchall():
                    records.append(PredictionRecord(
                        id=str(row[0]),
                        image_url=row[1],
                        crop_type=row[2],
                        confidence=row[3],
                        model_version=row[4],
                        timestamp=row[5],
                        processing_time_ms=row[6]
                    ))
                return records
        except Exception as e:
            logger.error(f"Failed to get predictions: {e}")
        
        return []
    
    async def get_stats(self) -> dict:
        """Get prediction statistics."""
        if not self.connected:
            return {}
        
        try:
            if self.db_type in ["sqlite", "postgresql"]:
                cursor = self.conn.cursor()
                
                # Total predictions
                cursor.execute("SELECT COUNT(*) FROM predictions")
                total = cursor.fetchone()[0]
                
                # Average confidence
                cursor.execute("SELECT AVG(confidence) FROM predictions")
                avg_confidence = cursor.fetchone()[0] or 0
                
                # Most common crop
                cursor.execute("""
                    SELECT crop_type, COUNT(*) as count
                    FROM predictions
                    GROUP BY crop_type
                    ORDER BY count DESC
                    LIMIT 1
                """)
                result = cursor.fetchone()
                top_crop = result[0] if result else "N/A"
                
                return {
                    "total_predictions": total,
                    "average_confidence": round(avg_confidence, 4),
                    "top_crop": top_crop
                }
        except Exception as e:
            logger.error(f"Failed to get stats: {e}")
        
        return {}
    
    async def close(self):
        """Close database connection."""
        try:
            if self.connected and hasattr(self, 'conn'):
                self.conn.close()
                logger.info("Database connection closed")
        except Exception as e:
            logger.error(f"Error closing database: {e}")

# Global database adapter instance
_db_adapter = None

async def get_database() -> DatabaseAdapter:
    """Get or create global database adapter."""
    global _db_adapter
    if _db_adapter is None:
        _db_adapter = DatabaseAdapter()
    return _db_adapter
