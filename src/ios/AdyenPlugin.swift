import Adyen

@objc(AdyenPlugin) class AdyenPlugin: CDVPlugin {
    var paymentRetrievalMutex: pthread_mutex_t = pthread_mutex_t()
    var paymentDataPayload: String!

    var callbackId: String!

    var appScheme: String!

    @objc(initializeCheckout:)
    func initializeCheckout(command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        self.paymentDataPayload = nil

        self.appScheme = command.arguments[0] as! String

        DispatchQueue(label: "com.seajas.checkout.main").async {
            let viewController = CheckoutViewController(delegate: self)
            self.viewController.present(viewController, animated: true)
        }
        
        pthread_mutex_init(&self.paymentRetrievalMutex, nil)
        pthread_mutex_lock(&self.paymentRetrievalMutex)
    }
    
    @objc(supplyPaymentData:)
    func supplyPaymentData(command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        self.paymentDataPayload = command.arguments[0] as! String

        pthread_mutex_unlock(&self.paymentRetrievalMutex)
    }
}

extension AdyenPlugin: CheckoutViewControllerDelegate {
    func checkoutViewController(_ controller: CheckoutViewController, requiresPaymentDataForToken token: String, completion: @escaping DataCompletion) {
        // Return control back to the JS layer to fetch the payment data

        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: token
        )
        commandDelegate!.send(pluginResult, callbackId: self.callbackId)

        // Now wait for the lock to be cleared and then complete the payment data

        DispatchQueue(label: "com.seajas.checkout.main").async {
            pthread_mutex_lock(&self.paymentRetrievalMutex)

            completion(self.paymentDataPayload.data(using: String.Encoding.utf8)!)

            pthread_mutex_unlock(&self.paymentRetrievalMutex)
        }
    }
    
    func checkoutViewController(_ controller: CheckoutViewController, requiresReturnURL completion: @escaping URLCompletion) {
        completion(URL(string: appScheme)!)
    }
    
    func checkoutViewController(_ controller: CheckoutViewController, didFinishWith result: PaymentRequestResult) {
        var success: Bool = false, cancelled: Bool = false
        var payload: String = "", errorMessage: String = ""
        
        switch result {
            case let .payment(payment):
                success = payment.status == .authorised
                payload = payment.payload
            case let .error(error):
                switch error {
                    case .canceled:
                        cancelled = true
                    default:
                        errorMessage = error.localizedDescription
                }
        }
        
        var pluginResult: CDVPluginResult = CDVPluginResult(
          status: CDVCommandStatus_ERROR,
          messageAs: cancelled ? "Payment was cancelled." : errorMessage
        )

        if success {
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAs: payload
            )
        }

        commandDelegate!.send(pluginResult, callbackId: self.callbackId)

        pthread_mutex_destroy(&self.paymentRetrievalMutex)

        self.viewController.dismiss(animated: true, completion: nil)
    }
}