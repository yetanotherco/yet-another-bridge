# MM Bot
MM Bot is a process designed to supply liquidity to YAB Escrow orders.
![img.png](images/img.png)
## Logical View
Requisitos funcionales
- El bot debe ser capaz de leer una orden del Escrow
- El bot debe ser capaz de realizar un transfer en Ethereum a la dirección de la orden
- El bot debe ser capaz de realizar un withdraw en Ethereum para recuperar los fondos en la L2
- El bot debe ser capaz de almacenar las ordenes en una base de datos e ir actualizando su estado
- En caso de error el bot debe ser capaz de almacenar el error y reintentar la orden



[Diagrama de clases]
## Process View
Requisitos no funcionales
- En caso de error el bot debe ser capaz de reintentar las ordenes fallidas
- El bot debe indexar las ordenes que pertenecen a bloques aceptados para
garantizar que no se pierden ordenes
- El bot debe estar disponible en todo momento
- El bot debe ser capaz de manejar multiples ordenes simultaneamente
- El bot debe ser capaz de recuperar el estado de las ordenes en caso de
interrupción
- El bot debe ser capaz de realizar logs adecuados para el seguimiento de las
ordenes
[Version simplificada de la arquitectura]

## Development View (TODO)

## Physical View
[Version completa de la arquitectura]

## Scenarios
1 Flujo de una orden
[Estado de una orden]

2 Orden fallida

3 Recuperacion de estado

4 Indexacion bloques aceptados
