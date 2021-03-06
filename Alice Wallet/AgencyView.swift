import SwiftUI

struct AgencyView: View {
    
    @ObservedObject var model: ViewModel = ViewModel()
    
    var body: some View {
        ScrollView() {
            VStack {
                Group {
                    agencyServerSettings()
                    provisionCloudAgentButton()
                    agencyClientSettings()
                    createAgencyClientForMainWalletButton()
                }
            }
            Spacer()
        }
    }
    
    fileprivate func provisionCloudAgentButton() -> some View {
        return Button(action: model.provisionCloudAgent) {
            Text("Provision Cloud Agent")
        }.buttonStyle(.bordered)
    }
    
    fileprivate func createAgencyClientForMainWalletButton() -> some View {
        return Button(action: model.createAgencyClientForMainWallet) {
            Text("Create Agency Client")
        }.buttonStyle(.bordered)
    }

    fileprivate func agencyServerSettings() -> some View {
        return Group {
            TextField("Agency Endpoint", text: $model.agencyEndpoint).textFieldStyle(.roundedBorder)
            TextField("Agency DID", text: $model.agencyDid).textFieldStyle(.roundedBorder)
            TextField("Agency VerKey", text: $model.agencyVerkey).textFieldStyle(.roundedBorder)
        }
    }
    
    fileprivate func agencyClientSettings() -> some View {
        return Group {
            TextField("Remote To SDK DID", text: $model.remoteToSdkDid).textFieldStyle(.roundedBorder)
            TextField("Remote To SDK VerKey", text: $model.remoteToSdkVerkey).textFieldStyle(.roundedBorder)
            TextField("SDK To Remote DID", text: $model.sdkToRemoteDid).textFieldStyle(.roundedBorder)
            TextField("SDK To Remote VerKey", text: $model.sdkToRemoteVerkey).textFieldStyle(.roundedBorder)
        }
    }
}
