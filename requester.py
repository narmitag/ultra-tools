import requests
import json
import os
import time

def send_slack_alert(webhook_url, free_storage_gb, total_storage_value, used_storage_value):
    """Send an alert to Slack webhook when storage is low."""
    try:
        message = {
            "text": "⚠️ Thor Storage Alert: Low Free Storage",
            "blocks": [
                {
                    "type": "header",
                    "text": {
                        "type": "plain_text",
                        "text": "⚠️ Storage Alert: Low Free Storage"
                    }
                },
                {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": f"*Free Storage:* {free_storage_gb} GB"
                        },
                        {
                            "type": "mrkdwn",
                            "text": f"*Total Storage:* {total_storage_value} GB"
                        },
                        {
                            "type": "mrkdwn",
                            "text": f"*Used Storage:* {used_storage_value} GB"
                        },
                        {
                            "type": "mrkdwn",
                            "text": f"*Threshold:* < 800 GB"
                        }
                    ]
                }
            ]
        }
        
        response = requests.post(webhook_url, json=message)
        if response.status_code == 200:
            print("Slack alert sent successfully")
        else:
            print(f"Failed to send Slack alert. Status code: {response.status_code}")
    except requests.exceptions.RequestException as e:
        print(f"Error sending Slack alert: {e}")

def send_request(url, auth_token, slack_webhook_url=None):
    try:
        # Create headers with authorization token
        headers = {
            'Authorization': f'Bearer {auth_token}'
        }

        # Send a GET request with the headers
        response = requests.get(url, headers=headers)

        # Check if the request was successful (status code 200)
        if response.status_code == 200:
            # Parse the JSON response
            data = response.json()
            storage_info = data.get('Storage Info', {})
            
            # Extract values as variables
            free_storage_bytes = storage_info.get('free_storage_bytes')
            free_storage_gb = storage_info.get('free_storage_gb')
            total_storage_unit = storage_info.get('total_storage_unit')
            total_storage_value = storage_info.get('total_storage_value')
            used_storage_unit = storage_info.get('used_storage_unit')
            used_storage_value = storage_info.get('used_storage_value')
            
            # Display the extracted variables
            print("Storage Information:")
            print(f"Free Storage (bytes): {free_storage_bytes}")
            print(f"Free Storage (GB): {free_storage_gb}")
            print(f"Total Storage: {total_storage_value} {total_storage_unit}")
            print(f"Used Storage: {used_storage_value} {used_storage_unit}")
            
            # Check if free storage is below threshold and send Slack alert
            if free_storage_gb is not None and free_storage_gb < 500:
                print(f"\n⚠️ Alert: Free storage ({free_storage_gb} GB) is below 800 GB threshold!")
                if slack_webhook_url:
                    send_slack_alert(slack_webhook_url, free_storage_gb, total_storage_value, used_storage_value)
                else:
                    print("Slack webhook URL not provided. Skipping alert.")
            
            # Return the variables as a dictionary for programmatic access
            return {
                'free_storage_bytes': free_storage_bytes,
                'free_storage_gb': free_storage_gb,
                'total_storage_unit': total_storage_unit,
                'total_storage_value': total_storage_value,
                'used_storage_unit': used_storage_unit,
                'used_storage_value': used_storage_value
            }
        else:
            print(f"Failed to retrieve data. Status code: {response.status_code}")
            return None

    except requests.exceptions.RequestException as e:
        # Handle any request exceptions
        print(f"An error occurred: {e}")
        return None
    except json.JSONDecodeError as e:
        # Handle JSON parsing errors
        print(f"Failed to parse JSON response: {e}")
        return None

if __name__ == "__main__":
    url = "https://narmitag.thor.usbx.me/ultra-api/get-diskquota"  # Replace with your desired URL
    auth_token = os.getenv("AUTH_TOKEN")
    slack_webhook_url = os.getenv("SLACK_WEBHOOK_URL")  # Get from environment variable

    # Loop forever, checking every 3 hours
    while True:
        send_request(url, auth_token, slack_webhook_url)
        print("Sleeping for 6 hours before next check...")
        time.sleep(6 * 60 * 60)


