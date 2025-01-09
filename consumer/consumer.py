import json
import os
import pg8000

def lambda_handler(event, context=None):
    """
    Lambda function to process API payload and push data into a PostgreSQL table.
    """

    # Log the entire incoming event for debugging

    # Check Authorization header
    authorization_header = event['headers'].get('Authorization', '')
    if not authorization_header.startswith('Bearer '):
        print("[Missing Bearer] Rejected event:", json.dumps(event, indent=2))
        return {
            'statusCode': 403,
            'body': json.dumps({'error': 'Unauthorized: Missing or invalid Authorization header'})
        }

    # Extract the token and validate it
    token = authorization_header[len('Bearer '):]
    allowed_tokens = os.getenv('SI_SUBMISSION_TOKENS', '').split(',')
    if token not in allowed_tokens:
        print("[Invalid Bearer] Rejected event:", json.dumps(event, indent=2))
        return {
            'statusCode': 403,
            'body': json.dumps({'error': 'Unauthorized: Missing or invalid Authorization header'})
        }

    # Parse payload
    payload = json.loads(event['body'])

    # Database connection details from environment variables or defaults for local testing against a local db or similar
    # Could be changed to IAM based authentication or similar in AWS if hosted there
    DB_HOST = os.getenv('DB_HOST', 'postgres')
    DB_PORT = int(os.getenv('DB_PORT', '5432'))
    DB_NAME = os.getenv('DB_NAME', 'postgres')
    DB_USER = os.getenv('DB_USER', 'postgres')
    DB_PASSWORD = os.getenv('DB_PASSWORD', 'postgres')

    try:
        # Establish connection to the PostgreSQL database
        connection = pg8000.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        cursor = connection.cursor()

        # Define SQL INSERT query
        insert_query = """
        INSERT INTO resources (
            display_name,
            unique_id,
            external_url,
            collected_timestamp,
            os_name,
            os_version,
            hardware_uuid,
            serial_number,
            applications,
            is_managed,
            auto_updates_enabled,
            owner,
            password_policy,
            is_xprotect_enabled,
            custom_properties,
            drives,
            submission_version
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """

        # Iterate through resources in the payload
        for resource in payload['resources']:
            # Prepare data for insertion
            data = (
                resource['displayName'],
                resource['uniqueId'],
                resource['externalUrl'],
                resource['collectedTimestamp'],
                resource['osName'],
                resource['osVersion'],
                resource['hardwareUuid'],
                resource['serialNumber'],
                json.dumps(resource.get('applications', [])),
                resource['isManaged'],
                resource['autoUpdatesEnabled'],
                resource['owner'],
                json.dumps(resource.get('passwordPolicy', {})),
                resource['isXProtectEnabled'],
                json.dumps(resource.get('customProperties', {})),
                json.dumps(resource.get('drives', [])),
                payload.get('submissionVersion', 'unknown')
            )

            # Execute SQL query
            cursor.execute(insert_query, data)

        # Commit transaction
        connection.commit()

    except Exception as e:
        # Rollback transaction in case of error
        if connection:
            connection.rollback()
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

    finally:
        # Close the connection
        if connection:
            cursor.close()
            connection.close()

    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Data inserted successfully for ' + resource['uniqueId']})
    }
