import UIKit
import WebKit

/// Sert les fichiers du dossier « www » embarqué dans l'app sous l'adresse app://local/…
/// Une vraie origine (et non file://) garantit que la sauvegarde du jeu (localStorage) fonctionne.
final class LocalSchemeHandler: NSObject, WKURLSchemeHandler {
    private let root: URL
    init(root: URL) { self.root = root }

    private func mime(_ ext: String) -> String {
        switch ext.lowercased() {
        case "html", "htm": return "text/html; charset=utf-8"
        case "js": return "application/javascript; charset=utf-8"
        case "css": return "text/css; charset=utf-8"
        case "json": return "application/json"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "svg": return "image/svg+xml"
        case "woff2": return "font/woff2"
        case "woff": return "font/woff"
        case "ttf": return "font/ttf"
        case "mp3": return "audio/mpeg"
        case "ogg": return "audio/ogg"
        case "wav": return "audio/wav"
        default: return "application/octet-stream"
        }
    }

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else { return }
        var path = url.path
        if path.isEmpty || path == "/" { path = "/index.html" }
        let file = root.appendingPathComponent(String(path.dropFirst()))
        guard file.standardizedFileURL.path.hasPrefix(root.standardizedFileURL.path),
              let data = try? Data(contentsOf: file) else {
            task.didFailWithError(NSError(domain: NSURLErrorDomain, code: NSURLErrorFileDoesNotExist))
            return
        }
        let headers = ["Content-Type": mime(file.pathExtension),
                       "Content-Length": String(data.count),
                       "Cache-Control": "no-cache"]
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}

final class GameViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {
    private var webView: WKWebView!
    private let saveKey = "chateau-de-poche-v2"
    private let backupKey = "chateauSaveBackup"

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    override func viewDidLoad() {
        super.viewDidLoad()
        let navy = UIColor(red: 20/255, green: 28/255, blue: 56/255, alpha: 1)
        view.backgroundColor = navy

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        if let www = Bundle.main.url(forResource: "www", withExtension: nil) {
            config.setURLSchemeHandler(LocalSchemeHandler(root: www), forURLScheme: "app")
        }

        let controller = WKUserContentController()
        controller.add(self, name: "saveBackup")
        controller.addUserScript(WKUserScript(source: bootstrapScript(), injectionTime: .atDocumentStart, forMainFrameOnly: true))
        config.userContentController = controller

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = navy
        webView.scrollView.backgroundColor = navy
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsLinkPreview = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        // Le jeu reste dans la zone sûre : rien ne passe sous l'encoche ni sous la barre d'accueil.
        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: g.topAnchor),
            webView.bottomAnchor.constraint(equalTo: g.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        webView.load(URLRequest(url: URL(string: "app://local/index.html")!))
    }

    /// Script injecté avant le jeu :
    /// 1. bloque le zoom, le menu contextuel et la sélection de texte ;
    /// 2. restaure la sauvegarde depuis la copie native si le localStorage a été vidé par iOS ;
    /// 3. recopie chaque sauvegarde dans les réglages de l'app (double sécurité).
    private func bootstrapScript() -> String {
        var restore = "null"
        if let saved = UserDefaults.standard.string(forKey: backupKey),
           let data = try? JSONSerialization.data(withJSONObject: [saved]),
           let literal = String(data: data, encoding: .utf8) {
            restore = literal + "[0]"
        }
        return """
        (function(){
          var K='\(saveKey)';
          try{var b=\(restore);if(b&&!localStorage.getItem(K))localStorage.setItem(K,b);}catch(e){}
          try{var orig=Storage.prototype.setItem;Storage.prototype.setItem=function(k,v){orig.call(this,k,v);
            if(k===K&&window.webkit&&webkit.messageHandlers&&webkit.messageHandlers.saveBackup){webkit.messageHandlers.saveBackup.postMessage(String(v));}};}catch(e){}
          document.addEventListener('gesturestart',function(e){e.preventDefault();},{passive:false});
          document.addEventListener('dblclick',function(e){e.preventDefault();},{passive:false});
          var st=document.createElement('style');
          st.textContent='html,body{-webkit-touch-callout:none;-webkit-user-select:none;user-select:none;touch-action:manipulation;-webkit-tap-highlight-color:transparent;overscroll-behavior:none}input,textarea{-webkit-user-select:text;user-select:text}';
          document.documentElement.appendChild(st);
        })();
        """
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "saveBackup", let s = message.body as? String {
            UserDefaults.standard.set(s, forKey: backupKey)
        }
    }

    // Les liens externes éventuels s'ouvrent dans Safari au lieu de remplacer le jeu.
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = action.request.url, action.navigationType == .linkActivated,
           let scheme = url.scheme, scheme.hasPrefix("http") {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    // Si iOS tue le moteur web en arrière-plan, on recharge le jeu (la sauvegarde est conservée).
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }
}
