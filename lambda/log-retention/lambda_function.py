import os
import logging
import psycopg2
from clickhouse_driver import Client
from datetime import datetime, timedelta

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_postgres_connection():
    """Create a connection to PostgreSQL database."""
    try:
        conn = psycopg2.connect(
            host=os.environ['POSTGRES_HOST'],
            port=os.environ['POSTGRES_PORT'],
            database=os.environ['POSTGRES_DB'],
            user=os.environ['POSTGRES_USER'],
            password=os.environ['POSTGRES_PASSWORD']
        )
        return conn
    except Exception as e:
        logger.error(f"Error connecting to PostgreSQL: {str(e)}")
        raise

def get_clickhouse_connection():
    """Create a connection to ClickHouse database."""
    try:
        client = Client(
            host=os.environ['CLICKHOUSE_HOST'],
            port=int(os.environ['CLICKHOUSE_PORT']),
            database=os.environ['CLICKHOUSE_DB'],
            user=os.environ['CLICKHOUSE_USER'],
            password=os.environ['CLICKHOUSE_PASSWORD']
        )
        return client
    except Exception as e:
        logger.error(f"Error connecting to ClickHouse: {str(e)}")
        raise

def clean_postgres_logs():
    """Clean old logs from PostgreSQL database."""
    try:
        conn = get_postgres_connection()
        cur = conn.cursor()
        
        # Get the retention period from environment variable
        retention_days = int(os.environ.get('LOG_RETENTION_DAYS', 30))
        cutoff_date = datetime.now() - timedelta(days=retention_days)
        
        # Delete old logs
        cur.execute("""
            DELETE FROM logs 
            WHERE created_at < %s
        """, (cutoff_date,))
        
        deleted_count = cur.rowcount
        conn.commit()
        cur.close()
        conn.close()
        
        logger.info(f"Deleted {deleted_count} old logs from PostgreSQL")
        return deleted_count
    except Exception as e:
        logger.error(f"Error cleaning PostgreSQL logs: {str(e)}")
        raise

def clean_clickhouse_logs():
    """Clean old logs from ClickHouse database."""
    try:
        client = get_clickhouse_connection()
        
        # Get the retention period from environment variable
        retention_days = int(os.environ.get('LOG_RETENTION_DAYS', 30))
        cutoff_date = datetime.now() - timedelta(days=retention_days)
        
        # Delete old logs
        result = client.execute("""
            ALTER TABLE logs DELETE WHERE created_at < %(cutoff_date)s
        """, {'cutoff_date': cutoff_date})
        
        logger.info(f"Deleted old logs from ClickHouse")
        return result
    except Exception as e:
        logger.error(f"Error cleaning ClickHouse logs: {str(e)}")
        raise

def lambda_handler(event, context):
    """Main Lambda handler function."""
    try:
        # Clean logs from both databases
        postgres_deleted = clean_postgres_logs()
        clickhouse_result = clean_clickhouse_logs()
        
        return {
            'statusCode': 200,
            'body': {
                'postgres_deleted': postgres_deleted,
                'clickhouse_cleaned': True
            }
        }
    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}")
        raise 