from services.payment_claimer.payment_claimer import PaymentClaimer


class Ethereum2ZksyncPaymentClaimer(PaymentClaimer):

    async def send_payment_claim(self, order, order_service):
        pass

    async def wait_for_payment_claim(self, order, order_service):
        pass

    async def close_payment_claim(self, order, order_service):
        pass
