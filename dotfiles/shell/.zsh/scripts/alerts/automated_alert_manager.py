import requests
import json

PROMETHEUS_URL = 'http://localhost:9090'
SLACK_WEBHOOK_URL = 'https://hooks.slack.com/services/your/webhook/url'
QUERY = 'ALERTS{alertstate="firing"}'

def get_prometheus_alerts():
    response = requests.get(f'{PROMETHEUS_URL}/api/v1/query', params={'query': QUERY})
    return response.json()

def send_slack_alert(alert):
    message = {'text': f"Alert: {alert['labels']['alertname']}\nSeverity: {alert['labels']['severity']}\nDescription: {alert['annotations']['description']}"}
    requests.post(SLACK_WEBHOOK_URL, data=json.dumps(message), headers={'Content-Type': 'application/json'})

if __name__ == "__main__":
    alerts = get_prometheus_alerts()['data']['result']
    for alert in alerts:
        send_slack_alert(alert)