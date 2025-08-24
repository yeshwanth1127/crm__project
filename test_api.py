import requests
import json

def test_features_endpoint():
    company_id = 1  # Replace with your actual company ID
    url = f"https://orbitco.in/api/subscription/company/{company_id}/features"
    
    try:
        response = requests.get(url)
        print(f"Status Code: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")
        print(f"Response Body: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"\nParsed JSON:")
            print(f"Features: {data.get('features', [])}")
            print(f"Plan Name: {data.get('plan_name', 'N/A')}")
            print(f"User Limit: {data.get('user_limit', 'N/A')}")
            print(f"Current Users: {data.get('current_users', 'N/A')}")
            print(f"Subscription Status: {data.get('subscription_status', 'N/A')}")
        else:
            print(f"Error: {response.status_code}")
            
    except Exception as e:
        print(f"Exception: {e}")

if __name__ == "__main__":
    test_features_endpoint()
