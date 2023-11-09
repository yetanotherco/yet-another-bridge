import constants
import requests
import os

def herodotus_prove(block) -> str:
    headers = {
        "Content-Type": "application/json",
    }

    request_data = {
    	"destinationChainId": HERODOTUS_DESTINATION_CHAIN,
    	"fee": "0",
    	"data": {
    	    HERODOTUS_ORIGIN_CHAIN: {
                "block:{}".format(block): {
                    "header": [
                        "PARENT_HASH",
                        "TRANSACTIONS_ROOT"
    	            ],
    	            "accounts": {
                        constants.ETH_CONTRACT_ADDR: {
                            "props": ["STORAGE_ROOT"]
                        }
                    }
                }
            }
        }
    }

    retries = 0
    while retries <= MAX_RETRIES:
        try:
            response = requests.post(
                'https://api.herodotus.cloud/submit-batch-query?apiKey={}'.format(HERODOTUS_API_KEY),
                headers=headers,
                json=request_data,
            )
            response.raise_for_status()
        
            return response.json()['internalId']
        except requests.exceptions.RequestException as err:
            retries += 1
            if retries == MAX_RETRIES:
                raise err
            time.sleep(RETRIES_DELAY)

def herodotus_status(task_id) -> str:
    try:
        response = requests.get(
            'https://api.herodotus.cloud/batch-query-status?apiKey={}&batchQueryId={}'.format(HERODOTUS_API_KEY, task_id),
        )
        response.raise_for_status()
    
        return response.json()['queryStatus']
    except requests.exceptions.RequestException as err:
        raise err

def herodotus_poll_status(task_id) -> bool:
    # instead of returning a bool we can store it in a mapping
    retries = 0
    while retries <= MAX_RETRIES:
        try:
            status = herodotus_status(task_id)
            if status == 'DONE':
                return True
            retries += 1
            time.sleep(RETRIES_DELAY)
        except requests.exceptions.RequestException as err:
            retries += 1
            if retries == MAX_RETRIES:
                raise err
            time.sleep(RETRIES_DELAY)

    return False
