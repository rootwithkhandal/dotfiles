import boto3
import datetime

client = boto3.client('ce', region_name='us-east-1')

def get_cost_and_usage(start_date, end_date):
    response = client.get_cost_and_usage(
        TimePeriod={'Start': start_date, 'End': end_date},
        Granularity='DAILY',
        Metrics=['UnblendedCost']
    )
    return response['ResultsByTime']

def main():
    end_date = datetime.datetime.utcnow().date()
    start_date = (end_date - datetime.timedelta(days=30)).isoformat()
    end_date = end_date.isoformat()
    costs = get_cost_and_usage(start_date, end_date)
    for day in costs:
        print(f"Date: {day['TimePeriod']['Start']}, Cost: {day['Total']['UnblendedCost']['Amount']}")

if __name__ == "__main__":
    main()