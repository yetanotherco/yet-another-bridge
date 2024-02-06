# MM Bot
MM Bot is a process designed to supply liquidity to YAB Escrow orders.

## Logical View
### Functional Requirements
- The bot must be able to read an order from the Escrow contract.
- The bot must be able to perform a transfer in Ethereum to the recipient address through the Payment
Registry contract.
- The bot must be able to perform a repay in Ethereum to recover the funds in the L2 through the
Payment Registry contract.
- The bot must be able to store the orders in a database and update their status.
- In case of an error, the bot must be able to store the error and retry the order.

### Simplified Class Diagram
The following diagram shows the mm classes and how they interact with each other.

![mm_diagram_class.svg](images%2Fmm_diagram_class.svg)

### Full Class Diagram
The following diagram is a detailed version of the previous diagram, 
showing the attributes and methods of each class.

![mm_diagram_class_full.svg](images%2Fmm_diagram_class_full.svg)

## Process View
### Non-Functional Requirements
- The bot must be able to handle multiple orders simultaneously.
- The bot must be able to retrieve the status of the orders in case of interruption and complete it.
- The bot must be highly available.
- The bot must index the orders that belong to accepted blocks to ensure that orders are not lost.
- The bot must be able to retry failed orders.
- The bot must be able to perform adequate logs for the orders tracking.

### Architecture
The bot architecture is as follows:

![architecture.png](images%2Farchitecture.png)
The bot is composed of the following components:
- **MM Bot**: The main process of the bot. It has the following subcomponents:
  - `Main Order Indexer`: The `Main Order Indexer` is responsible for indexing the orders from 
    the pending blocks.
  - `Order Processor`: The `Order Processor` is responsible for processing the orders.
  - `Failed Orders Processor`: The `Failed Orders Processor` is responsible for retrying the failed orders.
  It runs every 5 minutes.
  - `Accepted Blocks Processor`: The `Accepted Blocks Processor` is responsible for indexing the orders
    that belong to accepted blocks. It runs every 5 minutes.
- **Database**: The database is used to store the following data:
  - Orders.
  - Errors.
  - Block numbers.

An important aspect is that the bot must be able to handle multiple orders simultaneously.
For that reason, the bot uses asyncio to handle the orders concurrently. This way is preferred
over using threads, due to the potentially high number of orders that the bot must handle and 
the fact that the bot is I/O bound.

Another important aspect is that the bot must have a reliable network connection to communicate
with Ethereum and L2 networks RPCs.

## Physical View
The system is deployed in an EC2 virtual machine in AWS.
The EC2 runs the bot process and the database.

![physical_view.png](images/physical_view.png)

## Scenarios
### 1. Order Processing Flow
The following diagram shows the flow of an order through the bot.

![state_diagram.svg](images%2Fstate_diagram.svg)

### 2. Failed Orders Reprocessing
When an order fails, the bot stores the error and marks the order as failed. So, the `Failed
Orders Processor` will retry the failed orders. The following diagram shows the flow of a 
failed order through the bot.

![failed_orders.svg](images%2Ffailed_orders.svg)

### 3. Shutdown Recovery
When the bot starts, it retrieves incomplete orders from the database and continues their processing.

### Accepted Blocks Indexation
The Main Order Indexer process orders from pending blocks. The `Orders from
Accepted Blocks Processor` will index the orders that belong to accepted blocks. This way, if the `Main Order
Indexer` loses an order, it will be taken from the `Orders from Accepted Blocks Processor`.

![accepted_blocks.svg](images%2Faccepted_blocks.svg)
