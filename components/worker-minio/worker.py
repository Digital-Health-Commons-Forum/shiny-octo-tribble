#!/usr/bin/env python3

import os
import time
import json
import requests
import signal
import sys
import boto3
from urllib.parse import urlparse
from botocore.exceptions import NoCredentialsError, PartialCredentialsError

VERSION = '0.026'

worker_info = {
    'name': 'worker-minio',
    'description': 'This is a template worker written in Python.',
    'author': 'PGW',
    'offer': {
        'minio': 'This worker offers simple functions for dealing with minio'
    },
    'version': VERSION,
}

worker_state = {
    'status': 'running',
    'progress': 0,
    'message': 'Worker is running...',
    'data': {
        'stage': 1,
    }
}

api_url = os.getenv('MOJO_API_UI', 'http://127.0.0.1:3000/')

minio_credentials = {
    'minio_key_id': os.getenv('MINIO_ACCESS_KEY'),
    'minio_access_key': os.getenv('MINIO_SECRET_KEY'),
    'minio_uri': os.getenv('MINIO_URI', 'http://127.0.0.1:9000')
}

parsed_uri = urlparse(minio_credentials['minio_uri'])
minio_credentials.update({
    'minio_host': parsed_uri.hostname or '127.0.0.1',
    'minio_port': parsed_uri.port or 9000,
    'minio_scheme': parsed_uri.scheme if parsed_uri.scheme in ['http', 'https'] else 'http',
    'minio_secure': True if parsed_uri.scheme == 'https' else False,
})

if not minio_credentials['minio_key_id'] or not minio_credentials['minio_access_key']:
    raise ValueError('Missing Minio credentials')

def signal_handler(sig, frame):
    print(f"Received {signal.Signals(sig).name} signal, exiting...", file=sys.stderr)
    sys.exit(0)

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

def interact_with_openapi():
    while True:
        worker_state['data']['stage'] =
        additional_operation()
        if worker_state['data']['stage'] == 1:
            payload = json.dumps(worker_info)
            api_target = f"{api_url}/worker"
            print(f"Stage(1): Sending worker info to OpenAPI server... ({api_target})", file=sys.stderr)
            response = requests.post(api_target, headers={'Content-Type': 'application/json'}, data=payload)
            if response.status_code == 200:
                data = response.json()
                print(f"Received data from OpenAPI server: {data}")
                worker_state['data']['stage'] = 2
            else:
                print(f"Failed to connect to OpenAPI server: {response.status_code}", file=sys.stderr)
                print("Will retry in 5 seconds...", file=sys.stderr)
                time.sleep(5)
        else:
            response = requests.get(api_url)
            if response.status_code == 200:
                data = response.json()
                print(f"Received data from OpenAPI server: {data}")
            else:
                raise ConnectionError(f"Failed to connect to OpenAPI server: {response.status_code}")
        time.sleep(5)

def additional_operation():
    while True:
        print("Waiting", file=sys.stderr)
        if worker_state['data']['stage'] == 2:
            print("Stage(2): Validating minio presence & bucket 'media'...", file=sys.stderr)
            validate_minio()
        time.sleep(5)

def validate_minio():
    print("Validating Minio/S3 connection and checking for access...", file=sys.stderr)
    if worker_state['data']['stage'] == 2:
        initialize_minio()
    elif worker_state['data']['stage'] == 3:
        # Add your Minio/S3 validation logic here
        pass

def initialize_minio():
    print("Initializing Minio/S3 connection...", file=sys.stderr)
    try:
        s3_client = boto3.client(
            's3',
            endpoint_url=minio_credentials['minio_uri'],
            aws_access_key_id=minio_credentials['minio_key_id'],
            aws_secret_access_key=minio_credentials['minio_access_key'],
            use_ssl=minio_credentials['minio_secure']
        )

        # Check if bucket exists, if not create it
        bucket_name = 'media'
        try:
            s3_client.head_bucket(Bucket=bucket_name)
            print(f"Bucket '{bucket_name}' already exists", file=sys.stderr)
        except s3_client.exceptions.NoSuchBucket:
            s3_client.create_bucket(Bucket=bucket_name)
            print(f"Bucket '{bucket_name}' created successfully", file=sys.stderr)

        worker_state['data']['stage'] = 3
        validate_minio()
    except (NoCredentialsError, PartialCredentialsError) as e:
        print(f"Error during Minio setup: {e}", file=sys.stderr)

if __name__ == "__main__":
    time.sleep(5)
    interact_with_openapi()
    additional_operation()
