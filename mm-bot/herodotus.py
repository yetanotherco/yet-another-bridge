import asyncio
import logging
import constants
import requests
import time
from web3 import Web3

reqs = []
logger = logging.getLogger(__name__)


async def herodotus_prove(block, order_id, slot) -> str:
    headers = {
        "Content-Type": "application/json",
    }

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
                                hex(int(slot.hex(), 16) + 1),
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
            logger.error(err)
            retries += 1
            if retries == constants.MAX_RETRIES:
                raise err
        await asyncio.sleep(constants.RETRIES_DELAY)


def herodotus_status(task_id) -> str:
    try:
        response = requests.get(
            'https://api.herodotus.cloud/batch-query-status?apiKey={}&batchQueryId={}'.format(
                constants.HERODOTUS_API_KEY, task_id),
        )
        response.raise_for_status()

        return response.json()['queryStatus']
    except requests.exceptions.RequestException as err:
        logger.error(err)
        raise err


async def herodotus_poll_status(task_id) -> bool:
    # instead of returning a bool we can store it in a mapping
    retries = 0
    start_time = time.time()
    while retries <= constants.MAX_RETRIES:
        try:
            status = herodotus_status(task_id)
            logger.info(f"[+] Herodotus status: {status}")
            if status == 'DONE':
                end_time = time.time()
                request_time = end_time - start_time
                logger.info(f"[+] Herodotus request time: {request_time}")
                reqs.append(request_time)
                logger.info(f"[+] Herodotus average request time (total): {sum(reqs) / len(reqs)}")
                return True
            retries += 1
        except requests.exceptions.RequestException as err:
            logger.error(err)
            retries += 1
            if retries == constants.MAX_RETRIES:
                raise err
        await asyncio.sleep(constants.RETRIES_DELAY)
    return False
