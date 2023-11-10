import constants
import requests
import time
from web3 import Web3

def herodotus_prove(block, order_id) -> str:
    headers = {
        "Content-Type": "application/json",
    }

    slot = Web3.solidity_keccak(['uint256', 'uint256'], [order_id, 0])

    request_data = {
    	"destinationChainId": constants.HERODOTUS_DESTINATION_CHAIN,
    	"fee": "0",
    	"data": {
    	    constants.HERODOTUS_ORIGIN_CHAIN: {
                "block:{}".format(block): {
    	            "accounts": {
                        constants.ETH_CONTRACT_ADDR: {
                            "slots": [
                                slot.hex(),
                                hex(int(slot.hex(), 16) + 2),
                            ]
                        }
                    }
                }
            }
        }
    }

    retries = 0
    while retries <= constants.MAX_RETRIES:
        try:
            response = requests.post(
                'https://api.herodotus.cloud/submit-batch-query?apiKey={}'.format(constants.HERODOTUS_API_KEY),
                headers=headers,
                json=request_data,
            )
            response.raise_for_status()
        
            return response.json()['internalId']
        except requests.exceptions.RequestException as err:
            print(err)
            retries += 1
            if retries == constants.MAX_RETRIES:
                raise err
            time.sleep(constants.RETRIES_DELAY)

def herodotus_status(task_id) -> str:
    try:
        response = requests.get(
            'https://api.herodotus.cloud/batch-query-status?apiKey={}&batchQueryId={}'.format(constants.HERODOTUS_API_KEY, task_id),
        )
        response.raise_for_status()
    
        return response.json()['queryStatus']
    except requests.exceptions.RequestException as err:
        print(err)
        raise err

def herodotus_poll_status(task_id) -> bool:
    # instead of returning a bool we can store it in a mapping
    retries = 0
    while retries <= constants.MAX_RETRIES:
        try:
            status = herodotus_status(task_id)
            if status == 'DONE':
                return True
            retries += 1
            time.sleep(constants.RETRIES_DELAY)
        except requests.exceptions.RequestException as err:
            print(err)
            retries += 1
            if retries == constants.MAX_RETRIES:
                raise err
            time.sleep(constants.RETRIES_DELAY)

    return False
