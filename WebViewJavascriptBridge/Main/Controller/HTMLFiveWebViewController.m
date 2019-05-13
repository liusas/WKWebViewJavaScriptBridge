//
//  HTMLFiveWebViewController.m
//  WebViewDemo
//
//  Created by 刘峰 on 2019/4/4.
//  Copyright © 2019年 Liufeng. All rights reserved.
//

#import "HTMLFiveWebViewController.h"
#import <WebKit/WebKit.h>
#import "WKWebViewJavascriptBridge.h"

#define IPHONEXSeries           ([UIScreen mainScreen].bounds.size.height >= 810)
// 状态栏高度
#define STATUS_BAR_HEIGHT       (IPHONEXSeries ? 44.f : 20.f)
// 导航栏高度
#define NAVIGATION_BAR_HEIGHT   (IPHONEXSeries ? 88.f : 64.f)
// tabBar高度
#define TAB_BAR_HEIGHT          (IPHONEXSeries ? (49.f+34.f) : 49.f)
// home indicator
#define HOME_INDICATOR_HEIGHT   (IPHONEXSeries ? 34.f : 0.f)

@interface HTMLFiveWebViewController () <WKUIDelegate, WKNavigationDelegate, UINavigationBarDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) WKWebView *wkWebView;
@property (nonatomic, strong) WKWebViewJavascriptBridge *bridge;
@property (nonatomic, strong) UIImagePickerController *imagePicker;

@end

@implementation HTMLFiveWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.wkWebView];
    [self loadURL:[NSURL URLWithString:self.htmlUrl]];
    [self registerJSToOC];
}



/*
 *Web show
 */
- (void)loadURL:(NSURL *)url {
//    NSMutableURLRequest *requestObj = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    NSURL *htmlUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"WKWebView" ofType:@"html"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:htmlUrl];
    [self.wkWebView loadRequest:request];
}

/**
 注册js调用oc的函数名
 */
- (void)registerJSToOC{
    self.bridge = [WKWebViewJavascriptBridge bridgeForWebView:self.wkWebView];
    //如果要在ViewController中实现代理，就设置这个方法
    [self.bridge setWebViewDelegate:self];
    
    __weak typeof(self) weakSelf = self;
    //注册JS调用OC的函数名，handler是JS给的回调
    //JS第一个按钮点击事件
    [self.bridge registerHandler:@"firstClick" handler:^(id data, WVJBResponseCallback responseCallback) {
        //handler在主线程
        NSLog(@"thread = %@", [NSThread currentThread]);
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf firstClick:[data valueForKey:@"token"]];
        responseCallback([NSString stringWithFormat:@"成功调用OC的%@方法", [data valueForKey:@"action"]]);
    }];
    
    //JS第二个按钮点击事件
    [self.bridge registerHandler:@"secondClick" handler:^(id data, WVJBResponseCallback responseCallback) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf secondClick:[data valueForKey:@"token"]];
        responseCallback([NSString stringWithFormat:@"成功调用OC的%@方法", [data valueForKey:@"action"]]);
        
    }];
    //JS第三个按钮点击事件
    [self.bridge registerHandler:@"thirdClick" handler:^(id data, WVJBResponseCallback responseCallback) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf thirdClick:[data valueForKey:@"token"]];
        responseCallback([NSString stringWithFormat:@"成功调用OC的%@方法", [data valueForKey:@"action"]]);
    }];
    //JS第四个按钮点击事件
    [self.bridge registerHandler:@"forthClick" handler:^(id data, WVJBResponseCallback responseCallback) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf forthClick:[data valueForKey:@"token"]];
        responseCallback([NSString stringWithFormat:@"成功调用OC的%@方法", [data valueForKey:@"action"]]);
    }];
    //JS第五个按钮点击事件
    [self.bridge registerHandler:@"callOCToCallJSClick" handler:^(id data, WVJBResponseCallback responseCallback) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf firstClick:[data valueForKey:@"token"]];
        responseCallback([NSString stringWithFormat:@"成功调用OC的%@方法", [data valueForKey:@"action"]]);
    }];
}

//OC调用JS的按钮点击事件
- (IBAction)callJSButtonClick:(UIBarButtonItem *)sender {
    [self.bridge callHandler:@"showTextOnDiv" data:@"这是OC调用JS方法" responseCallback:^(id responseData) {
        NSLog(@"showTextOnDiv的回调responseData = %@", responseData);
    }];
}

#pragma mark - WKNavigationDelegate
/**
 根据url来判断webview是否跳转到外部链接
 */
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;

    [self wkWebViewWillStart:url];

    decisionHandler(WKNavigationActionPolicyAllow);
}

/**
 根据服务器返回的响应头判断是否可以跳转外链
 */
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    decisionHandler(WKNavigationResponsePolicyAllow);
}

/**
 页面开始加载
 */
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {

}

/**
 页面加载失败
 */
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {

}

/**
 当页面内容开始返回时调用
 */
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {

}

/**
 页面加载完成时调用
 */
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [webView evaluateJavaScript:@"document.title" completionHandler:^(id _Nullable title, NSError * _Nullable error) {
        self.title = title;
    }];

    NSLog(@"加载了一次");
}

/**
 webview即将开始加载网页

 @param url 网页的url
 */
- (void)wkWebViewWillStart:(NSURL *)url {
    if (![self isBlankString:url.absoluteString] && ![url.absoluteString isEqualToString:@"about:blank"]) {
    }
    if (!self.wkWebView.canGoBack) {//webview是否可以返回
    }
    else {
    }
}

//第一个按钮点击事件
- (void)firstClick:(NSString *)str {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:str preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:confirm];
    [self presentViewController:alertController animated:YES completion:nil];
}

//第二个按钮点击事件
- (void)secondClick:(NSString *)str {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:str preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:confirm];
    [self presentViewController:alertController animated:YES completion:nil];
}

//第三个按钮点击事件
- (void)thirdClick:(NSString *)str {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:str preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:confirm];
    [self presentViewController:alertController animated:YES completion:nil];
}

//第五个按钮点击事件，调用OC执行JS来调用JS的弹窗
- (void)callOCToCallJSClick:(NSString *)str1 str2:(nonnull NSString *)str2 {
    //OC调用JS方法一, webview的stringByEvaluatingJavaScriptFromString
    //    [self.webView stringByEvaluatingJavaScriptFromString:@"ocToJS('OC调用JS连接两个字符串', '哈哈啊哈')"];
    //OC调用JS方法二,JSContext的callWithArguments
    
    
}

- (void)forthClick:(NSString *)str {
    if (!self.imagePicker) {
        self.imagePicker = [[UIImagePickerController alloc] init];
    }
    self.imagePicker.delegate = self;
    self.imagePicker.allowsEditing = YES;
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:self.imagePicker animated:YES completion:nil];
}

#pragma mark - WKUIDelegate
// 创建一个新的WebView, 比如要打开一个word或PDF文件，需要在这里创建一个新的webView，再从decidePolicyForNavigationResponse代理方法中再给这个webView干掉
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (!navigationAction.targetFrame.isMainFrame) {
        //这里创建新的webview
    }
    return nil;
}

#pragma mark -- UIImagePickerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSLog(@"info---%@",info);
    UIImage *resultImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    NSData *imgData = UIImageJPEGRepresentation(resultImage, 0.01);
    NSString *encodedImageStr = [imgData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    [self dismissViewControllerAnimated:YES completion:nil];
    NSString *imageString = [self clearImageString:encodedImageStr];
    
    //OC调用JS
    [self.bridge callHandler:@"showImageOnDiv" data:imageString responseCallback:^(id responseData) {
        NSLog(@"respnseData = %@", responseData);
    }];
    //这样也行
//    NSString *jsFunctStr = [NSString stringWithFormat:@"showImageOnDiv('%@')",imageString];
//    [self.wkWebView evaluateJavaScript:jsFunctStr completionHandler:^(id _Nullable name, NSError * _Nullable error) {
//        NSLog(@"完事儿");
//    }];
    
    
}

//清除base64串里面的东西
- (NSString *)clearImageString:(NSString *)str {
    NSString *temp = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    temp = [temp stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    temp = [temp stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return temp;
}

#pragma mark - Getter
- (WKWebView *)wkWebView {
    if (!_wkWebView) {
        CGRect frame = CGRectZero;
        frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-HOME_INDICATOR_HEIGHT);
        
        _wkWebView = [[WKWebView alloc] initWithFrame:frame];
        _wkWebView.navigationDelegate = self;
        _wkWebView.UIDelegate = self;
    }
    return _wkWebView;
}

#pragma mark - Tools
- (BOOL)isBlankString:(NSString *)string {
    if (string == nil || string == NULL) {
        return YES;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0) {
        return YES;
    }
    return NO;
}

- (NSString *)getURLString:(NSString *)string {
    
    NSError *error = nil;
    // URL regular expression
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(http|https)://((\\w)*|([-])*)+([\\.|/]((\\w)*|([-])*))+" options:0 error:&error];
    if ( error ) {
        return nil;
    }
    
    NSTextCheckingResult *res = [regex firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
    if (res != nil) {
        return string;
    }
    return nil;
}

- (BOOL)isMatchWithString:(NSString *)string andPattern:(NSString *)pattern {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    if (error) {
        return NO;
    }
    NSTextCheckingResult *result = [regex firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
    return result ? YES : NO;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
