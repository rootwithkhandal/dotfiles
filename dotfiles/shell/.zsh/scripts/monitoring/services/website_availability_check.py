import requests
try:
    response = requests.get("http://example.com")
    print("Website is up!") if response.status_code == 200 else print("Website is down!")
except:
    print("Website Unreachable!")