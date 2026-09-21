import requests
from datetime import datetime, timedelta

# Elasticsearch configuration
ELASTICSEARCH_URL = 'http://localhost:9200'
INDEX_NAME = 'logs'

def get_logs():
    end_time = datetime.now()
    start_time = end_time - timedelta(hours=1)
    query = {
        "query": {
            "bool": {
                "must": [
                    {"match": {"message": "HTTP 500"}}
                ],
                "filter": {
                    "range": {
                        "@timestamp": {
                            "gte": start_time.isoformat(),
                            "lte": end_time.isoformat()
                        }
                    }
                }
            }
        }
    }
    response = requests.get(f'{ELASTICSEARCH_URL}/{INDEX_NAME}/_search', json=query)
    response.raise_for_status()
    return response.json()

def parse_logs(log_data):
    hits = log_data['hits']['hits']
    for hit in hits:
        log_message = hit['_source'].get('message', 'No message')
        timestamp = hit['_source']['@timestamp']
        print(f'{timestamp}: {log_message}')

if __name__ == "__main__":
    log_data = get_logs()
    parse_logs(log_data)