//
//  ViewController.swift
//  cloakfb
//
//  Created by  Hsu Ching Feng on 03/10/2017.
//  Copyright © 2017 App Design. All rights reserved.
//

import UIKit
import WebKit
import AudioToolbox

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, UIScrollViewDelegate {

    enum CurrentPage {
        case Facebook, Messenger, Other
    }

    var webView: WKWebView!
    var wkConfig: WKWebViewConfiguration!
    var refreshControl: UIRefreshControl!
    var bottomRefreshIndicator: UIActivityIndicatorView!
    let homepageUrl = URL(string: "https://www.messenger.com")!
    var currentPage = CurrentPage.Messenger
    let impactFeedback = UIImpactFeedbackGenerator(style: .light)

    @objc func onSwipe(_ sender: UISwipeGestureRecognizer) {
        if currentPage == .Messenger {
            print(sender.direction)
            impactFeedback.impactOccurred()
            let showSidebar = sender.direction == .right

            if showSidebar {
                webView.evaluateJavaScript("document.querySelector('._1enh').style='display:unset !important'", completionHandler: nil)
            } else {
                webView.evaluateJavaScript("document.querySelector('._1enh').style='display:none !important'", completionHandler: nil)
            }

            UserDefaults.standard.set(showSidebar, forKey: "friendsSidebar")
            preinjectScript(showFriendsSideBar: showSidebar)
            UserDefaults.standard.synchronize()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let guide = view.safeAreaLayoutGuide

        wkConfig = WKWebViewConfiguration()
        webView = WKWebView(frame: CGRect.zero, configuration: wkConfig)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.refreshWebView(_:)), for: UIControlEvents.valueChanged)
        
        webView.scrollView.addSubview(refreshControl)
        webView.scrollView.keyboardDismissMode = .interactive
        webView.scrollView.delegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            webView.topAnchor.constraint(equalTo: guide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
        ])

        bottomRefreshIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        bottomRefreshIndicator.color = UIColor.gray
        bottomRefreshIndicator.center = CGPoint(x: guide.layoutFrame.width / 2, y: guide.layoutFrame.maxY + 20)
        webView.scrollView.addSubview(bottomRefreshIndicator)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.onSwipe(_:)))
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.onSwipe(_:)))
        swipeRight.direction = .right
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
        view.addGestureRecognizer(swipeRight)
        
        UserDefaults.standard.register(defaults: ["friendsSidebar": true])
        impactFeedback.prepare()
        
        let ruleJSON = """
            [
                {
                    "trigger": {
                        "url-filter": "https://www.facebook.com/ajax/messaging/typ.php.*"
                    },
                    "action": {
                        "type": "block"
                    }
                },
                {
                    "trigger": {
                        "url-filter": "https://www.messenger.com/ajax/messaging/typ.php.*"
                    },
                    "action": {
                        "type": "block"
                    }
                },
                {
                    "trigger": {
                        "url-filter": "https://www.facebook.com/ajax/mercury/delivery_receipts.php.*"
                    },
                    "action": {
                        "type": "block"
                    }
                },
                {
                    "trigger": {
                        "url-filter": "https://www.messenger.com/ajax/mercury/delivery_receipts.php.*"
                    },
                    "action": {
                        "type": "block"
                    }
                },
                {
                    "trigger": {
                        "url-filter": "https://www.facebook.com/ajax/mercury/change_read_status.php.*"
                    },
                    "action": {
                        "type": "block"
                    }
                },
                {
                    "trigger": {
                        "url-filter": "https://www.messenger.com/ajax/mercury/change_read_status.php.*"
                    },
                    "action": {
                        "type": "block"
                    }
                },
                {
                    "trigger": {
                        "url-filter": "https://www.facebook.com/ajax/chat/.*"
                    },
                    "action": {
                        "type": "block"
                    }
                },
                {
                    "trigger": {
                        "url-filter": "https://[0-9]?-?edge-chat.*"
                    },
                    "action": {
                        "type": "block"
                    }
                },
                {
                    "trigger": {
                        "url-filter": "https://m.facebook.com/messages.*"
                    },
                    "action": {
                        "type": "block"
                    }
                },
                {
                    "trigger": {
                        "url-filter": "https://m.facebook.com/buddylist.php.*"
                    },
                    "action": {
                        "type": "block"
                    }
                },
                {
                    "trigger": {
                        "url-filter": "https://www.facebook.com/ajax/bz"
                    },
                    "action": {
                        "type": "block"
                    }
                },
                {
                    "trigger": {
                        "url-filter": "https://m.facebook.com/ajax/a/bz"
                    },
                    "action": {
                        "type": "block"
                    }
                },
                {
                    "trigger": {
                        "url-filter": "https://www.facebook.com/common/scribe_endpoint.php.*"
                    },
                    "action": {
                        "type": "block"
                    }
                },
                {
                    "trigger": {
                        "url-filter": "https://www.messenger.com/common/scribe_endpoint.php.*"
                    },
                    "action": {
                        "type": "block"
                    }
                }
            ]
        """;

        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36"

        WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "CloakFB", encodedContentRuleList: ruleJSON) { (ruleList, error) in
            if let error = error {
                print(error);
                return
            }
            guard let ruleList = ruleList else {
                return
            }

            self.wkConfig.userContentController.add(ruleList);
            self.preinjectScript(showFriendsSideBar: UserDefaults.standard.bool(forKey: "friendsSidebar"))

            self.webView.load(URLRequest(url: self.homepageUrl))
        }
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            if let host = url.host {
                switch host {
                case "www.facebook.com":
                    currentPage = .Facebook
                    webView.load(URLRequest(url: URL(string: url.absoluteString.replacingOccurrences(of: "//www", with: "//m"))!))
                    decisionHandler(.cancel)
                    return
                case "m.facebook.com":
                    currentPage = .Facebook
                case "www.messenger.com":
                    currentPage = .Messenger
                default:
                    print("unknown \(host)")
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                    decisionHandler(.cancel)
                    return
                }
            }
        }
        decisionHandler(.allow)
    }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
        return nil
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if currentPage == .Messenger, !UserDefaults.standard.bool(forKey: "friendsSidebar") {
            webView.evaluateJavaScript("document.querySelector('._1enh').style='display:none'", completionHandler: nil)
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    @objc func refreshWebView(_ sender: UIRefreshControl) {
        refreshControl.endRefreshing()
        if let url = webView.url {
            webView.load(URLRequest(url: url))
        } else {
            webView.load(URLRequest(url: homepageUrl))
        }
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 20, currentPage == .Messenger {
            bottomRefreshIndicator.startAnimating()
            bottomRefreshIndicator.alpha = (scrollView.contentOffset.y - 20) / 100
        }
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y > 100, currentPage == .Messenger {
            bottomRefreshIndicator.stopAnimating()
            webView.reload()
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        bottomRefreshIndicator.stopAnimating()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { (context) in
        }) { (context) in
            let guide = self.view.safeAreaLayoutGuide
            self.bottomRefreshIndicator.center = CGPoint(x: guide.layoutFrame.width / 2, y: guide.layoutFrame.maxY + 20)
        }
    }
    
    func preinjectScript(showFriendsSideBar: Bool) {
        let script = """
            (function(pushState, replaceState){
                var meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.documentElement.appendChild(meta);

                var style = document.createElement('style');
        style.innerHTML = 'body { overflow: hidden !important; max-width: 100% !important; max-height: 100% !important; } ._4sp8 { min-width: 0 !important; } ._p0g.error, ._39bj:nth-child(2), ._fl2 li:not(:last-child) \(showFriendsSideBar ? "" : ", ._1enh") { display: none !important; }';
                document.documentElement.appendChild(style);

                history.pushState = function (state, title, url) {
                    if (url && url.indexOf('messages') > 0 ) {
                        location.href = "https://www.messenger.com";
                        return false;
                    }
                    return pushState.apply(this, arguments);
                }
                history.replaceState = function (state, title, url) {
                    if (url && url.indexOf('messages') > 0 ) {
                        location.href = "https://www.messenger.com";
                        return false;
                    }
                    return replaceState.apply(this, arguments);
                }

            })(history.pushState, history.replaceState)
        """
        self.wkConfig.userContentController.removeAllUserScripts()
        self.wkConfig.userContentController.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true))
    }
}
