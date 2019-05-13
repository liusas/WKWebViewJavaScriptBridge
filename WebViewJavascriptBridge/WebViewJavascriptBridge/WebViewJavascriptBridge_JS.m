// This file contains the source for the Javascript side of the
// WebViewJavascriptBridge. It is plaintext, but converted to an NSString
// via some preprocessor tricks.
//
// Previous implementations of WebViewJavascriptBridge loaded the javascript source
// from a resource. This worked fine for app developers, but library developers who
// included the bridge into their library, awkwardly had to ask consumers of their
// library to include the resource, violating their encapsulation. By including the
// Javascript as a string resource, the encapsulation of the library is maintained.

#import "WebViewJavascriptBridge_JS.h"

NSString * WebViewJavascriptBridge_js() {
	#define __wvjb_js_func__(x) #x
	
	// BEGIN preprocessorJSCode
	static NSString * preprocessorJSCode = @__wvjb_js_func__(
;(function() {
    // 如果已经有了WebViewJavascriptBridge对象，就证明已经初始化过了
	if (window.WebViewJavascriptBridge) {
		return;
	}

	if (!window.onerror) {
		window.onerror = function(msg, url, line) {
			console.log("WebViewJavascriptBridge: ERROR:" + msg + "@" + url + ":" + line);
		}
	}
    //初始化WebViewJavascriptBridge对象，相当于构造函数
	window.WebViewJavascriptBridge = {
		registerHandler: registerHandler,
		callHandler: callHandler,
		disableJavscriptAlertBoxSafetyTimeout: disableJavscriptAlertBoxSafetyTimeout,
		_fetchQueue: _fetchQueue,
		_handleMessageFromObjC: _handleMessageFromObjC
	};
        
    //iFrame，用来被OC拦截url的
	var messagingIframe;
    //存放OC与JS交互的JSON类型对象{函数名和参数}的列表
	var sendMessageQueue = [];
    //存放函数名的JSON对象
	var messageHandlers = {};
	//OC中会根据下面这两个值一起判断是否属于WebViewJavaScriptBridge框架的消息
	var CUSTOM_PROTOCOL_SCHEME = 'https';
	var QUEUE_HAS_MESSAGE = '__wvjb_queue_message__';
    /*
     存放callHandler时的block回调信息
     存放callBack回调的JSON类型对象
     {"callbackId":"objc_cb_1","data":"这是OC调用JS方法","handlerName":"showTextOnDiv"}
     其中callbackId由uniqueId和时间戳确定
     */
	var responseCallbacks = {};
	var uniqueId = 1;
    //是否使用判断超时
	var dispatchMessagesWithTimeoutSafety = true;
    //注册OC调用JS的函数名和回调到WebViewJavaScriptBridge对象
	function registerHandler(handlerName, handler) {
        //用messageHandlers把函数名存储起来
		messageHandlers[handlerName] = handler;
	}
	//JS调用OC方法的函数
	function callHandler(handlerName, data, responseCallback) {
		if (arguments.length == 2 && typeof data == 'function') {
			responseCallback = data;
			data = null;
		}
        //发送消息
		_doSend({ handlerName:handlerName, data:data }, responseCallback);
	}
    //不设置超时操作
	function disableJavscriptAlertBoxSafetyTimeout() {
		dispatchMessagesWithTimeoutSafety = false;
	}
    /*
    *发送消息给OC（调用OC的方法）
    *message:{handlerName:handlerName, data:data, callbackId:callbackId}，
    *{"responseId":"cb_2_1557736087950","responseData":"成功调用OC的firstClick方法"}
    *{"callbackId":"objc_cb_1","data":"这是OC调用JS方法","handlerName":"showTextOnDiv"}
    *responseCallback:OC给的回调
    */
	function _doSend(message, responseCallback) {
		if (responseCallback) {
			var callbackId = 'cb_'+(uniqueId++)+'_'+new Date().getTime();
			responseCallbacks[callbackId] = responseCallback;
			message['callbackId'] = callbackId;
		}
		sendMessageQueue.push(message);
		messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
	}
    /*
     *获取JS的调用OC的消息组，把JS的消息数组转换成JSON字符串
     */
	function _fetchQueue() {
		var messageQueueString = JSON.stringify(sendMessageQueue);
		sendMessageQueue = [];
		return messageQueueString;
	}
    /*
     *处理主动消息或回调消息
     *这里OC调用JS有分为两种类型，一种是应答消息(response)类型，一种是回收消息(callback)类型
     应答消息(response)类型的messageJSON:
     {\"responseId\":\"cb_1_1557747121840\",\"responseData\":\"成功调用OC的firstClick方法\"}
     回收消息(callback)类型的messageJSON:
     {\"callbackId\":\"objc_cb_1\",\"data\":\"这是OC调用JS方法\",\"handlerName\":\"showTextOnDiv\"}
     */
	function _dispatchMessageFromObjC(messageJSON) {
		if (dispatchMessagesWithTimeoutSafety) {
			setTimeout(_doDispatchMessageFromObjC);
		} else {
			 _doDispatchMessageFromObjC();
		}
		
		function _doDispatchMessageFromObjC() {
			var message = JSON.parse(messageJSON);
			var messageHandler;
			var responseCallback;

			if (message.responseId) {
				responseCallback = responseCallbacks[message.responseId];
				if (!responseCallback) {
					return;
				}
				responseCallback(message.responseData);
				delete responseCallbacks[message.responseId];
			} else {
				if (message.callbackId) {
					var callbackResponseId = message.callbackId;
					responseCallback = function(responseData) {
						_doSend({ handlerName:message.handlerName, responseId:callbackResponseId, responseData:responseData });
					};
				}
				
				var handler = messageHandlers[message.handlerName];
				if (!handler) {
					console.log("WebViewJavascriptBridge: WARNING: no handler for message from ObjC:", message);
				} else {
					handler(message.data, responseCallback);
				}
			}
		}
	}
	//把消息发送给JS
	function _handleMessageFromObjC(messageJSON) {
        _dispatchMessageFromObjC(messageJSON);
	}

	messagingIframe = document.createElement('iframe');
	messagingIframe.style.display = 'none';
	messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
	document.documentElement.appendChild(messagingIframe);

	registerHandler("_disableJavascriptAlertBoxSafetyTimeout", disableJavscriptAlertBoxSafetyTimeout);
	
	setTimeout(_callWVJBCallbacks, 0);
	function _callWVJBCallbacks() {
		var callbacks = window.WVJBCallbacks;
		delete window.WVJBCallbacks;
		for (var i=0; i<callbacks.length; i++) {
			callbacks[i](WebViewJavascriptBridge);
		}
	}
})();
	); // END preprocessorJSCode

	#undef __wvjb_js_func__
	return preprocessorJSCode;
};
