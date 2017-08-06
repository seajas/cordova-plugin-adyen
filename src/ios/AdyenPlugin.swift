import Adyen

@objc(AdyenPlugin)
class AdyenPlugin: CDVPlugin {
    var paymentDataCompletion: DataCompletion!

    var callbackId: String!

    var appScheme: String!

    @objc(initializeCheckout:)
    func initializeCheckout(command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        self.appScheme = command.arguments[0] as! String

        let viewController = CheckoutViewController(delegate: self)
        self.viewController.present(viewController, animated: true)
    }
    
    @objc(supplyPaymentData:)
    func supplyPaymentData(command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        self.paymentDataCompletion((command.arguments[0] as! String).data(using: String.Encoding.utf8)!)
    }
}

extension AdyenPlugin: CheckoutViewControllerDelegate {
    func checkoutViewController(_ controller: CheckoutViewController, requiresPaymentDataForToken token: String, completion: @escaping DataCompletion) {
        self.paymentDataCompletion = completion

        // Return control back to the JS layer to fetch the payment data

        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: token
        )

        commandDelegate!.send(pluginResult, callbackId: self.callbackId)
    }
    
    func checkoutViewController(_ controller: CheckoutViewController, requiresReturnURL completion: @escaping URLCompletion) {
        completion(URL(string: appScheme)!)
    }
    
    func checkoutViewController(_ controller: CheckoutViewController, didFinishWith result: PaymentRequestResult) {
        var pluginResult: CDVPluginResult

        switch result {
            case let .payment(payment):
                if (payment.status == .authorised || payment.status == .received) {
                    pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAs: payment.payload
                    )
                } else {
                    pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: "Payment was \(payment.status.rawValue)"
                    )
                }
            case let .error(error):
                switch error {
                    case .canceled:
                        pluginResult = CDVPluginResult(
                            status: CDVCommandStatus_ERROR,
                            messageAs: "Payment was cancelled"
                        )
                    default:
                        pluginResult = CDVPluginResult(
                            status: CDVCommandStatus_ERROR,
                            messageAs: error.localizedDescription
                        )
                }
        }

        commandDelegate!.send(pluginResult, callbackId: self.callbackId)

        self.viewController.dismiss(animated: true, completion: nil)
    }
}
