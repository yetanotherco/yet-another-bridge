from functools import wraps


def use_fallback(rpc_nodes, logger, error_message="Failed"):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            exceptions = []
            for rpc_node in rpc_nodes:
                try:
                    return func(*args, **kwargs, rpc_node=rpc_node)
                except Exception as exception:
                    logger.warning(f"[-] {error_message}: {exception}")
                    exceptions.append(exception)
            logger.error(f"[-] {error_message} from all nodes")
            raise Exception(f"{error_message} from all nodes: [{', '.join(str(e) for e in exceptions)}]")

        return wrapper

    return decorator


def use_async_fallback(rpc_nodes, logger, error_message="Failed"):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            exceptions = []
            for rpc_node in rpc_nodes:
                try:
                    return await func(*args, **kwargs, rpc_node=rpc_node)
                except Exception as exception:
                    logger.warning(f"[-] {error_message}: {exception}")
                    exceptions.append(exception)
            logger.error(f"[-] {error_message} from all nodes")
            raise Exception(f"{error_message} from all nodes: [{', '.join(str(e) for e in exceptions)}]")

        return wrapper

    return decorator

