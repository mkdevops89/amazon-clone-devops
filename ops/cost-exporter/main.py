import boto3
import time
import os
import logging
from datetime import datetime, timedelta
from prometheus_client import start_http_server, Gauge

# Setup Logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Environment Variables
AWS_REGION = os.environ.get('AWS_REGION', 'us-east-1')
SCRAPE_INTERVAL = int(os.environ.get('SCRAPE_INTERVAL', 21600)) # Default 6 hours
PORT = int(os.environ.get('PORT', 8000))

# Prometheus Metrics
TOTAL_COST = Gauge('aws_billing_estimated_charges_total', 'Total estimated billing charges for the current month')
SERVICE_COST = Gauge('aws_billing_service_cost_total', 'Estimated billing charges per service', ['service'])

def get_cost_and_usage():
    """
    Queries AWS Cost Explorer for Month-to-Date costs.
    Groups by SERVICE.
    """
    try:
        client = boto3.client('ce', region_name=AWS_REGION)
        
        # Date Range: First day of current month to Today
        today = datetime.now()
        start_date = today.replace(day=1).strftime('%Y-%m-%d')
        end_date = today.strftime('%Y-%m-%d')

        # If it's the 1st of the month, AWS API requires end_date > start_date
        # So we query the previous month or handle typically.
        # Minimal fix: if start == end, add 1 day to end (though usually CE has 24h delay)
        if start_date == end_date:
             # Fallback for Day 1: Query nothing or last month? 
             # Let's just return 0 to avoid crash, actual data appears on Day 2 usually.
             logger.info("First day of month, skipping query to avoid date range error.")
             return

        logger.info(f"Querying AWS Cost Explorer from {start_date} to {end_date}...")

        response = client.get_cost_and_usage(
            TimePeriod={'Start': start_date, 'End': end_date},
            Granularity='MONTHLY',
            Metrics=['UnblendedCost'],
            GroupBy=[{'Type': 'DIMENSION', 'Key': 'SERVICE'}]
        )

        total_bill = 0.0

        for group in response['ResultsByTime'][0]['Groups']:
            service_name = group['Keys'][0]
            amount = float(group['Metrics']['UnblendedCost']['Amount'])
            
            # Update Prometheus Metric
            SERVICE_COST.labels(service=service_name).set(amount)
            total_bill += amount
            
        # Update Total Metric
        TOTAL_COST.set(total_bill)
        logger.info(f"Updated metrics. Total Bill MTD: ${total_bill:.2f}")

    except Exception as e:
        logger.error(f"Failed to query AWS Cost Explorer: {e}")

if __name__ == '__main__':
    logger.info(f"Starting AWS Cost Exporter on port {PORT}...")
    start_http_server(PORT)
    
    while True:
        get_cost_and_usage()
        logger.info(f"Sleeping for {SCRAPE_INTERVAL} seconds...")
        time.sleep(SCRAPE_INTERVAL)
