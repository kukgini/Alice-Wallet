import Foundation
import SwiftyJSON
import vcx
import SwiftUI
import Alamofire

public enum ConnectionStatus: NSNumber {
    case initialized = 1
    case request_sent = 2
    case offer_received = 3
    case accepted = 4
    
    func description() -> String {
        switch self {
        case .initialized:
            return "Initialzied"
        case .request_sent:
            return "Request Sent"
        case .offer_received:
            return "Offer Received"
        case .accepted:
            return "Accepted"
        }
    }
    
    func color() -> Color {
        switch self {
        case .initialized:
            return Color.white
        case .request_sent:
            return Color.yellow
        case .offer_received:
            return Color.blue
        case .accepted:
            return Color.green
        }
    }
    
    func icon() -> String {
        switch self {
        case .initialized:
            return "icloud"
        case .request_sent:
            return "icloud"
        case .offer_received:
            return "icloud"
        case .accepted:
            return "link.icloud.fill"
        }
    }
}

public enum CredentialStatus: NSNumber {
    case initialized = 1
    case request_sent = 2
    case offer_received = 3
    case accepted = 4
    
    func description() -> String {
        switch self {
        case .initialized:
            return "Initialzied"
        case .request_sent:
            return "Request Sent"
        case .offer_received:
            return "Offer Received"
        case .accepted:
            return "Accepted"
        }
    }
    
    func color() -> Color {
        switch self {
        case .initialized:
            return Color.white
        case .request_sent:
            return Color.yellow
        case .offer_received:
            return Color.blue
        case .accepted:
            return Color.green
        }
    }
    
    func icon() -> String {
        switch self {
        case .initialized:
            return "icloud"
        case .request_sent:
            return "icloud"
        case .offer_received:
            return "icloud"
        case .accepted:
            return "link.icloud.fill"
        }
    }
}


class ViewModel : ObservableObject {

    @Published var wallets: [String] = []
    @Published var networks: [URL] = []
    
    @Published var walletKeyDerivationFunction = "ARGON2I_MOD"

    @Published var ledgerGenesisURL = "http://test.bcovrin.vonx.io/genesis"
    @Published var genesisTransaction = UserDefaults.standard.string(forKey:"GenesisTransaction") ??  ""
    
    @Published var agencyEndpoint = "https://devariesvcx.duckdns.org"
//    @Published var agencyEndpoint = "https://ariesvcx.agency.staging.absa.id"
    @Published var agencyDid = "VsKV7grR1BUE29mG2Fm2kX"
    @Published var agencyVerkey = "Hezce2UWMZ3wUhVkh2LfKSs8nDzWwzs2Win7EzNN3YaR"

    @Published var remoteToSdkDid = "" // pairwise DID of this client's agent in the agency. aka, remote_to_sdk_did
    @Published var remoteToSdkVerkey = "" // verkey of this client's agent in the agency. aka, remote_to_sdk_verkey
    @Published var sdkToRemoteDid = "" // pairwise DID of this client used to communicate with it's agent in the agency. aka, sdk_to_remote_did
    @Published var sdkToRemoteVerkey = "" // verkey of this client used to commnicate with it's agent in the agency. aka, sdk_to_remote_verkey
    @Published var inviteDetails = ""
    @Published var connections: [String:(
        handle:NSNumber,
        status:ConnectionStatus,
        inviteDetails:JSON,
        selected:Bool)] = [:]
    @Published var message = ""
    @Published var credentials: [NSNumber:NSNumber] = [:]
    
    init() {
        self.loadWallets()
        self.loadNetworks()
    }
    
    @Published var walletOpened = false
    @Published var poolOpened = false
    @Published var agencyProvisioned = false
    @Published var agencyClientCreated = false
    
    func onboardingCompleted() -> Bool {
        return walletOpened && poolOpened && agencyProvisioned && agencyClientCreated
    }
    
    func loadWallets() {
        let urls = VcxAdaptor.shared.listWalletURLs()
        self.wallets = []
        print("wallets:")
        for (index, url) in urls.enumerated() {
            let walletName = url.lastPathComponent
            print("\t* [\(index)] \(walletName)")
            self.wallets.append(walletName)
        }
    }
    
    func createWallet(name:String,key:String) {
        let config = """
        {
            "wallet_name": "\(name)",
            "wallet_key": "\(key)",
            "wallet_key_derivation": "\(self.walletKeyDerivationFunction)"
        }
        """
        print("create wallet. config=", config)
        VcxAdaptor.shared.createWallet(config:config, completion:{ error in
            if error != nil && error!._code > 0 {
                print("create wallet failed: ", error!.localizedDescription)
            } else {
                print("create wallet success.")
            }
        })
    }
    
    func openWallet(name:String,key:String) {
        let config = """
        {
            "wallet_name": "\(name)",
            "wallet_key": "\(key)",
            "wallet_key_derivation": "\(self.walletKeyDerivationFunction)"
        }
        """
        print("open wallet. config=", config)
        VcxAdaptor.shared.openMainWallet(config:config, completion:{ error, handle in
            if error != nil && error!._code > 0 {
                print("open wallet failed. handle=\(handle!), error=\(error!.localizedDescription)")
            } else {
                print("open wallet success. handle=\(handle!)")
                self.walletOpened = true
            }
        })
    }
    
    func loadNetworks() {
        self.networks = VcxAdaptor.shared.listNetworkTxURLs()
        print("networks:")
        for (index, url) in self.networks.enumerated() {
            let networkName = url.lastPathComponent
            print("\t* [\(index)] \(networkName)")
        }
    }
    
    func openMainPool(name:String) {
        let url = Bundle.main.url(forResource:"Networks/\(name)", withExtension: "json")!
        let config = """
        {
            "genesis_path": "\(url.path)",
            "pool_name": "\(name)"
        }
        """
        print("open main pool. config=\n", config)
        VcxAdaptor.shared.vcxOpenMainPool(config:config, completion:{ error in
            if error != nil && error!._code > 0 {
                print("open main pool failed. error=", error!.localizedDescription)
            } else {
                print("open main pool successed.")
                self.poolOpened = true
            }
        })
    }

    func provisionCloudAgent() {
        let config = """
        {
            "agency_endpoint": "\(agencyEndpoint)",
            "agency_did": "\(agencyDid)",
            "agency_verkey": "\(agencyVerkey)"
        }
        """
        print("provision cloud agent. config=", config)
        VcxAdaptor.shared.vcxProvisionCloudAgent(config: config, completion: { error, result in
            if error != nil && error!._code > 0 {
                print("provision cloud agent failed. error=", error!.localizedDescription)
            } else {
                print("provision cloud agent successed.")
                let json = try! JSON(data: result!.data(using: .utf8)!)
                self.remoteToSdkDid    = json["remote_to_sdk_did"].string!
                self.remoteToSdkVerkey = json["remote_to_sdk_verkey"].string!
                self.sdkToRemoteDid    = json["sdk_to_remote_did"].string!
                self.sdkToRemoteVerkey = json["sdk_to_remote_verkey"].string!
                print("json=\(json)")
                
                self.agencyProvisioned = true
            }
        })
    }
    
    func createAgencyClientForMainWallet() {
        let config = """
        {
            "agency_endpoint": "\(agencyEndpoint)",
            "agency_did": "\(agencyDid)",
            "agency_verkey": "\(agencyVerkey)",
            "remote_to_sdk_did": "\(remoteToSdkDid)",
            "remote_to_sdk_verkey": "\(remoteToSdkVerkey)",
            "sdk_to_remote_did": "\(sdkToRemoteDid)",
            "sdk_to_remote_verkey": "\(sdkToRemoteVerkey)"
        }
        """
        VcxAdaptor.shared.vcxCreateAgencyClient(forMainWallet: config, completion: { error in
            if error != nil && error!._code > 0 {
                print("provision cloud agent failed. error=", error!.localizedDescription)
            } else {
                print("provision cloud agent successed.")
                self.agencyClientCreated = true
            }
        })
    }
    
    func getConnectionHandle(id:String) -> NSNumber {
        return self.connections[id]!.handle
    }
    
    func receiveInvitation() {
        // url encoded invitation ????????? ?????? ?c_i= ????????? ?????? base64 ????????? ?????? json invitation ??? ??????
        let json = try! JSON(data: inviteDetails.data(using: .utf8)!)
        let id = json["@id"].string!
        print("receive invitation. id=\(id), detail=\(inviteDetails)")
        self.connectionCreate(id:id,invitateDetails:json)
    }
    
    func connectionNextStep(id:String) {
        let c = self.connections[id]!
        print("connection handle=\(c.handle) id=\(id) status=\(c.status.rawValue.description)")
        switch c.status {
        case .initialized:
            print("connection next step is connect.")
            connectionConnect(id: id)
        case .request_sent:
            print("waiting to be accepted")
        case .offer_received:
            print("waiting to be accepted")
        case .accepted:
            print("waiting to be accepted")
        }
        self.connectionStatusUpdate()
    }
    
    func connectionCreate(id:String,invitateDetails:JSON) {
        print("connection create. id=\(id), inviteDetails=\(invitateDetails)")
        VcxAdaptor.shared.connectionCreate(
            withInvite: id,
            inviteDetails: inviteDetails,
            completion: { error, handle in
                if error != nil && error!._code > 0 {
                    print("connection create failed. error=", error!.localizedDescription)
                } else {
                    print("connection create successed. handle=", handle!)
                    self.connections[id] = (
                        handle:handle!,
                        status:ConnectionStatus.initialized,
                        inviteDetails:invitateDetails,
                        selected: false
                    )
                }
        })
    }
    
    func connectionConnect(id:String) {
        let c = connections[id]!
        let connectionType = "{\"use_public_did\":false}"
        print("connection connect. id=\(id), handle=\(c.handle), connectionType=\(connectionType)")
        VcxAdaptor.shared.connectionConnect(
            withHandle:c.handle,
            connectionType:connectionType,
            completion: { error in
                if error != nil && error!._code > 0 {
                    print("connection connect failed. error=", error!.localizedDescription)
                } else {
                    print("connection connect successed.")
                }
            }
        )
    }
    
    func connectionStatusGet(id:String) {
        let c = connections[id]!
        VcxAdaptor.shared.connectionGetState(
            withHandle: c.handle,
            completion: { error, status in
                if error != nil && error!._code > 0 {
                    print("connection create failed. error=\(error!.localizedDescription)")
                } else {
                    print("connection create successed. id=\(id), handle=\(c.handle), status=\(status!)")
                    self.connections[id] = (
                        handle: c.handle,
                        status: ConnectionStatus(rawValue:status!)!,
                        inviteDetails: c.inviteDetails,
                        selected: c.selected
                    )
                }
            }
        )
    }
    
    func connectionStatusUpdate() {
        for (id, c) in connections {
            print("connection status update. id=\(id), handle=\(c.handle), statue=\(c.status)")
            VcxAdaptor.shared.connectionUpdateState(
                withHandle:c.handle,
                completion: {error, status in
                    if error != nil && error!._code > 0 {
                        print("connection status update failed. error=", error!.localizedDescription)
                    } else {
                        print("connection status update successed. status=", status!)
                        self.connections[id] = (
                            handle:c.handle,
                            status:ConnectionStatus(rawValue:status!)!,
                            inviteDetails: c.inviteDetails,
                            selected: false
                        )
                    }
            })
        }
    }
    
    func credentialsStatusUpdate() {
        self.connectionStatusUpdate()
        for (id, c) in connections {
            VcxAdaptor.shared.credentialGetOffers(
                withHandle:c.handle,
                completion:{error, offers in
                    if error != nil && error!._code > 0 {
                        print("get credential offers for connection id=\(id) failed. error=", error!.localizedDescription)
                    } else {
                        print("get credential offers for connection id=\(id) successed.")
                        let offer = offers?.dropFirst().dropLast()
                        VcxAdaptor.shared.credentialCreateWithOffer(
                            sourceId:id,
                            offer:String(offer!),
                            completion: { error, credentialHandle in
                                if error != nil && error!._code > 0 {
                                    print("create credential with offer failed. error=", error!.localizedDescription)
                                } else {
                                    print("create credential with offer successed. credentialHandle=", credentialHandle!)
                                    self.credentials[credentialHandle!] = c.handle
                                    VcxAdaptor.shared.credentialSendRequest(
                                        credentialHandle: credentialHandle!,
                                        connectionHandle: c.handle,
                                        completion: { error in
                                            if error != nil && error!._code > 0 {
                                                print("credential request failed. error=", error!.localizedDescription)
                                            } else {
                                                print("credential request successed.")
                                            }
                                        }
                                    )
                                }
                            }
                        )
                    }
                }
            )
        }
        for (credentialHandle, connectionHandle) in credentials {
            VcxAdaptor.shared.credentialUpdateStateV2(
                credentialHandle: credentialHandle,
                connectionHandle: connectionHandle,
                completion: { error, status in
                    if error != nil && error!._code > 0 {
                        print("credential update state failed. error=", error!.localizedDescription)
                    } else {
                        print("credential update state successed. credentialHandle=\(credentialHandle) connectionHandle=\(connectionHandle) statue=\(status!)")
                        if status! == CredentialStatus.accepted.rawValue {
                            VcxAdaptor.shared.getCredential(
                                credentialHandle: credentialHandle,
                                completion: { error, credential in
                                    if error != nil && error!._code > 0 {
                                        print("get credential failed. error=", error!.localizedDescription)
                                    } else {
                                        print("get credential successed. credential=\(credential!)")
                                    }
                                }
                            )
                        }
                    }
                }
            )
        }
    }
    
    func connectionToggleSelection(id:String) {
        let c = self.connections[id]!
        self.connections[id] = (
            handle: c.handle,
            status: c.status,
            inviteDetails: c.inviteDetails,
            selected: !c.selected
        )
    }
    
    func connectionIsSelected(id:String) -> Bool {
        return self.connections[id]!.selected
    }
    
    func connectionSendMessage(id:String) {
        let c = self.connections[id]!
        print("connection send message. id=\(id), handle=\(c.handle), statue=\(c.status)")
        VcxAdaptor.shared.connectionSendBasicMessage(
            withHandle:c.handle,
            message: self.message,
            options: "",
            completion: {error, status in
                if error != nil && error!._code > 0 {
                    print("connection send message failed. error=", error!.localizedDescription)
                } else {
                    print("connection send message successed. status=", status!)
                }
        })
    }
    
    func credentialGetOffers(id:String) {
        let c = self.connections[id]!
        print("credential get offers in connection. id=\(id)")
        VcxAdaptor.shared.credentialGetOffers(
            withHandle:c.handle,
            completion: {error, offers in
                if error != nil && error!._code > 0 {
                    print("credential get offers failed. error=", error!.localizedDescription)
                } else {
                    for offer in offers! {
                        print("connection=\(id) offer=\(offer)")
                    }
                }
        })
    }
    
}
