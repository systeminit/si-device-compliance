import os
import pg8000
import botocore.vendored.requests as requests
import json

# Environment variables
DB_HOST = os.getenv('DB_HOST', 'example-db.c9m4osgyqdow.us-east-1.rds.amazonaws.com')
DB_PORT = int(os.getenv('DB_PORT', '5432'))
DB_NAME = os.getenv('DB_NAME', 'rdsexampledb')
DB_USER = os.getenv('DB_USER', 'postgres')
DB_PASSWORD = os.getenv('DB_PASSWORD', '2ZhcFBF09gKOaA7zHkTq')
VANTA_API_URL = "https://api.vanta.com/v1/resources/macos_user_computer"
VANTA_SUBMISSION_TOKEN = os.getenv("VANTA_SUBMISSION_TOKEN")

def get_latest_events():
    """
    Retrieve the latest event for each unique_id from the database.
    """
    connection = None
    try:
        connection = pg8000.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
        )
        cursor = connection.cursor()

        query = """
        SELECT unique_id, display_name, external_url, collected_timestamp, os_name, os_version,
               hardware_uuid, serial_number, applications, users, browser_extensions,
               system_screenlock_policies, is_managed, auto_updates_enabled, owner,
               password_policy, is_xprotect_enabled, custom_properties, drives
        FROM resources
        WHERE (unique_id, collected_timestamp) IN (
            SELECT unique_id, MAX(collected_timestamp)
            FROM resources
            GROUP BY unique_id
        )
        """
        cursor.execute(query)
        rows = cursor.fetchall()
        
        print('Some rows below:')
        print(rows)

        events = []
        for row in rows:
            events.append({
                "uniqueId": row[0],
                "displayName": row[1],
                "externalUrl": row[2],
                "collectedTimestamp": row[3].isoformat(),
                "osName": row[4],
                "osVersion": row[5],
                "hardwareUuid": row[6],
                "serialNumber": row[7],
                "applications": json.loads(row[8]) if isinstance(row[8], str) else row[8] or [],
                "users": json.loads(row[9]) if isinstance(row[9], str) else row[9] or [],
                "browserExtensions": json.loads(row[10]) if isinstance(row[10], str) else row[10] or [],
                "systemScreenlockPolicies": json.loads(row[11]) if isinstance(row[11], str) else row[11] or [],
                "isManaged": row[12],
                "autoUpdatesEnabled": row[13],
                "owner": row[14],
                "passwordPolicy": json.loads(row[15]) if isinstance(row[15], str) else row[15] or {},
                "isXProtectEnabled": row[16],
                "customProperties": json.loads(row[17]) if isinstance(row[17], str) else row[17] or {},
                "drives": json.loads(row[18]) if isinstance(row[18], str) else row[18] or [],
            })

        return events

    except Exception as e:
        print(f"Error retrieving events: {e}")
        return []

    finally:
        if connection:
            connection.close()

def submit_to_vanta(events):
    """
    Submit events to the Vanta API.
    """
    headers = {
        "accept": "application/json",
        "content-type": "application/json",
        "Authorization": f"Bearer {VANTA_SUBMISSION_TOKEN}",
    }

    payload = {
        "resources": events,
        "resourceId": "674e31cd9e54bdf0bec0222e",  # Update as needed
    }

    try:
        response = requests.put(VANTA_API_URL, headers=headers, json=payload)
        if response.status_code == 200:
            print("Submission successful!")
        else:
            print(f"Failed to submit: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Error during submission: {e}")

def lambda_handler(event, context):
    """
    Main function to execute the uploader.
    """
    events = get_latest_events()
    if events:
        submit_to_vanta(events)
    else:
        print("No events to submit.")
