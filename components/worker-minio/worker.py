#!/usr/bin/env python

import requests
import json
import pprint

# Details about this worker
worker_info = {
    'name': 'worker-template-python',
    'description': 'This is a template worker written in Python.',
    'author': 'PGW'
}

# A place to store worker state
worker_state = {
    'status': 'running',
    'progress': 0,
    'message': 'Worker is running...',
    'data': {
        'stage': 1,
    }
}

# OpenAPI server URL
api_url = 'http://127.0.0.1:3000/'

def interact_with_openapi():
    # Should really use a proper HTTP client library here, but this is just a template
    if worker_state['data']['stage'] == 1:
        payload = json.dumps(worker_info)
        api_target = api_url + "worker"
        
        print("Stage(1): Sending worker info to OpenAPI server...")
        response = requests.post(api_target, headers={'Content-Type': 'application/json'}, data=payload)

        if response.status_code == 200:
            data = response.json()
            print("Received data from OpenAPI server: ")
            pprint.pprint(data)
            worker_state['data']['stage'] = 2
        else:
            raise Exception(f"Failed to connect to OpenAPI server: {response.status_code}")
    else:
        response = requests.get(api_url)

        if response.status_code == 200:
            data = response.json()
            print("Received data from OpenAPI server: ")
            pprint.pprint(data)
        else:
            raise Exception(f"Failed to connect to OpenAPI server: {response.status_code}")

def additional_operation():
    print("Performing additional operation...\n")
    # Add your additional operation code here

if __name__ == "__main__":
    interact_with_openapi()
    additional_operation()