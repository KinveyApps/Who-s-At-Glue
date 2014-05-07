//
//  LoginViewController.m
//  WhosAtGlue
//
//  Created by Michael Katz on 3/17/14.
//  Copyright 2014 Kinvey, Inc
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
#import "LoginViewController.h"

#import <KinveyKit/KinveyKit.h>

#import "KCSUser+WhosAtGlue.h"
#import "EmailPwdLoginTableViewController.h"

#import "NSError+WhosAtGlue.h"
#import "ProgressHUD.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor backgroundColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
 
    if ([CLLocationManager isRangingAvailable] && [CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        if ([KCSUser activeUser]) {
            [self showSetup];
        }
    } else {
        [self showCantUseApp];
    }
}

- (IBAction)signUpWithLinkedIn:(id)sender
{
    UIWebView* webView = [[UIWebView alloc] init];
    UIViewController* webViewController = [[UIViewController alloc] init];
    webViewController.automaticallyAdjustsScrollViewInsets = YES;
    webViewController.view = webView;
    webView.scalesPageToFit = YES;
    
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    webView.scrollView.contentInset = UIEdgeInsetsMake(statusBarHeight, 0, 0, 0);
    
    NSString* script = @"!function(a,b){\"object\"==typeof exports?module.exports=b():\"function\"==typeof define&&define.amd?define(b):a.Spinner=b()}(this,function(){\"use strict\";function a(a,b){var c,d=document.createElement(a||\"div\");for(c in b)d[c]=b[c];return d}function b(a){for(var b=1,c=arguments.length;c>b;b++)a.appendChild(arguments[b]);return a}function c(a,b,c,d){var e=[\"opacity\",b,~~(100*a),c,d].join(\"-\"),f=.01+c/d*100,g=Math.max(1-(1-a)/b*(100-f),a),h=j.substring(0,j.indexOf(\"Animation\")).toLowerCase(),i=h&&\"-\"+h+\"-\"||\"\";return l[e]||(m.insertRule(\"@\"+i+\"keyframes \"+e+\"{0%{opacity:\"+g+\"}\"+f+\"%{opacity:\"+a+\"}\"+(f+.01)+\"%{opacity:1}\"+(f+b)%100+\"%{opacity:\"+a+\"}100%{opacity:\"+g+\"}}\",m.cssRules.length),l[e]=1),e}function d(a,b){var c,d,e=a.style;for(b=b.charAt(0).toUpperCase()+b.slice(1),d=0;d<k.length;d++)if(c=k[d]+b,void 0!==e[c])return c;return void 0!==e[b]?b:void 0}function e(a,b){for(var c in b)a.style[d(a,c)||c]=b[c];return a}function f(a){for(var b=1;b<arguments.length;b++){var c=arguments[b];for(var d in c)void 0===a[d]&&(a[d]=c[d])}return a}function g(a,b){return\"string\"==typeof a?a:a[b%a.length]}function h(a){this.opts=f(a||{},h.defaults,n)}function i(){function c(b,c){return a(\"<\"+b+' xmlns=\"urn:schemas-microsoft.com:vml\" class=\"spin-vml\">',c)}m.addRule(\".spin-vml\",\"behavior:url(#default#VML)\"),h.prototype.lines=function(a,d){function f(){return e(c(\"group\",{coordsize:k+\" \"+k,coordorigin:-j+\" \"+-j}),{width:k,height:k})}function h(a,h,i){b(m,b(e(f(),{rotation:360/d.lines*a+\"deg\",left:~~h}),b(e(c(\"roundrect\",{arcsize:d.corners}),{width:j,height:d.width,left:d.radius,top:-d.width>>1,filter:i}),c(\"fill\",{color:g(d.color,a),opacity:d.opacity}),c(\"stroke\",{opacity:0}))))}var i,j=d.length+d.width,k=2*j,l=2*-(d.width+d.length)+\"px\",m=e(f(),{position:\"absolute\",top:l,left:l});if(d.shadow)for(i=1;i<=d.lines;i++)h(i,-2,\"progid:DXImageTransform.Microsoft.Blur(pixelradius=2,makeshadow=1,shadowopacity=.3)\");for(i=1;i<=d.lines;i++)h(i);return b(a,m)},h.prototype.opacity=function(a,b,c,d){var e=a.firstChild;d=d.shadow&&d.lines||0,e&&b+d<e.childNodes.length&&(e=e.childNodes[b+d],e=e&&e.firstChild,e=e&&e.firstChild,e&&(e.opacity=c))}}var j,k=[\"webkit\",\"Moz\",\"ms\",\"O\"],l={},m=function(){var c=a(\"style\",{type:\"text/css\"});return b(document.getElementsByTagName(\"head\")[0],c),c.sheet||c.styleSheet}(),n={lines:12,length:7,width:5,radius:10,rotate:0,corners:1,color:\"#000\",direction:1,speed:1,trail:100,opacity:.25,fps:20,zIndex:2e9,className:\"spinner\",top:\"50%\",left:\"50%\",position:\"absolute\"};h.defaults={},f(h.prototype,{spin:function(b){this.stop();{var c=this,d=c.opts,f=c.el=e(a(0,{className:d.className}),{position:d.position,width:0,zIndex:d.zIndex});d.radius+d.length+d.width}if(b&&(b.insertBefore(f,b.firstChild||null),e(f,{left:d.left,top:d.top})),f.setAttribute(\"role\",\"progressbar\"),c.lines(f,c.opts),!j){var g,h=0,i=(d.lines-1)*(1-d.direction)/2,k=d.fps,l=k/d.speed,m=(1-d.opacity)/(l*d.trail/100),n=l/d.lines;!function o(){h++;for(var a=0;a<d.lines;a++)g=Math.max(1-(h+(d.lines-a)*n)%l*m,d.opacity),c.opacity(f,a*d.direction+i,g,d);c.timeout=c.el&&setTimeout(o,~~(1e3/k))}()}return c},stop:function(){var a=this.el;return a&&(clearTimeout(this.timeout),a.parentNode&&a.parentNode.removeChild(a),this.el=void 0),this},lines:function(d,f){function h(b,c){return e(a(),{position:\"absolute\",width:f.length+f.width+\"px\",height:f.width+\"px\",background:b,boxShadow:c,transformOrigin:\"left\",transform:\"rotate(\"+~~(360/f.lines*k+f.rotate)+\"deg) translate(\"+f.radius+\"px,0)\",borderRadius:(f.corners*f.width>>1)+\"px\"})}for(var i,k=0,l=(f.lines-1)*(1-f.direction)/2;k<f.lines;k++)i=e(a(),{position:\"absolute\",top:1+~(f.width/2)+\"px\",transform:f.hwaccel?\"translate3d(0,0,0)\":\"\",opacity:f.opacity,animation:j&&c(f.opacity,f.trail,l+k*f.direction,f.lines)+\" \"+1/f.speed+\"s linear infinite\"}),f.shadow&&b(i,e(h(\"#000\",\"0 0 4px #000\"),{top:\"2px\"})),b(d,b(i,h(g(f.color,k),\"0 0 1px rgba(0,0,0,.1)\")));return d},opacity:function(a,b,c){b<a.childNodes.length&&(a.childNodes[b].style.opacity=c)}});var o=e(a(\"group\"),{behavior:\"url(#default#VML)\"});return!d(o,\"transform\")&&o.adj?i():j=d(o,\"animation\"),h});";
    NSString* html = [NSString stringWithFormat:@"<html><head><script>%@</script><body><div id='foo'></div><script>var opts = {  lines: 13,  length: 25,  width: 11,  radius: 30,  corners: 1,  rotate: 0,   direction: 1,  color: '#000',   speed: 1,   trail: 60,  shadow: false,  hwaccel: false,   className: 'spinner'}; var target = document.getElementById('foo');var spinner = new Spinner(opts).spin(target);</script></body>", script];
    [webView loadHTMLString:html baseURL:nil];
    [self presentViewController:webViewController animated:YES completion:^{
        [KCSUser getAccessDictionaryFromLinkedIn:^(NSDictionary *accessDictOrNil, NSError *errorOrNil) {
            if (errorOrNil) {
                [errorOrNil alert:@"Unable to contact LinkedIn" vc:self];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self dismissViewControllerAnimated:YES completion:nil];
                });
            } else {
                [KCSUser loginWithSocialIdentity:KCSSocialIDLinkedIn accessDictionary:accessDictOrNil withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [ProgressHUD dismiss];
                    });
                    if (errorOrNil) {
                        [errorOrNil alert:@"Unable to log in" vc:self];
                    } else {
                        [self showSetup];
                    }
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self dismissViewControllerAnimated:NO completion:nil];
                    [ProgressHUD show:@"Logging in..."];
                });
            }
        } permissions:@"r_basicprofile,r_emailaddress" usingWebView:webView];
    }];
    
};

- (IBAction)loginWithEmail:(id)sender
{
    UIStoryboard* sb = [UIStoryboard storyboardWithName:@"EmailPassword" bundle:nil];
    UIViewController* restOfLogin = [sb instantiateInitialViewController];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:restOfLogin animated:YES completion:nil];
    });
}

- (void) showSetup
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([KCSUser activeUser].setup) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            UIStoryboard* sb = [UIStoryboard storyboardWithName:@"UserProfile" bundle:nil];
            UIViewController* restOfLogin = [sb instantiateInitialViewController];
            [self presentViewController:restOfLogin animated:YES completion:nil];
        }
    });
}

- (IBAction)signUpWithEmail:(id)sender
{
    UIStoryboard* sb = [UIStoryboard storyboardWithName:@"EmailPassword" bundle:nil];
    UINavigationController* restOfLogin = [sb instantiateInitialViewController];
    EmailPwdLoginTableViewController* cavc = (id)[restOfLogin topViewController];
    cavc.createAccount = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:restOfLogin animated:YES completion:nil];
    });

}

- (void) showCantUseApp
{
    UILabel* infoLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
    infoLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    infoLabel.textColor = [UIColor whiteColor];
    infoLabel.font = [UIFont boldSystemFontOfSize:28.];
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.numberOfLines = 0;
    infoLabel.userInteractionEnabled = YES;
    infoLabel.tag = 3000;
    [self.view addSubview:infoLabel];
    
#if IN_DEVELOPMENT
    UITapGestureRecognizer* dblTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideInfoLabel)];
    dblTap.numberOfTapsRequired = 2;
    //    dblTap.numberOfTouchesRequired = 2;
    [infoLabel addGestureRecognizer:dblTap];
#endif

    infoLabel.text = @"iBeacon technology is unavailable for this device. Please visit the Kinvey booth for a demonstration.";
}

- (void) hideInfoLabel
{
    [[self.view viewWithTag:3000] removeFromSuperview];
    [ProgressHUD show:@"Creating anonymous user..."];
    [KCSUser createAutogeneratedUser:nil completion:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        [ProgressHUD dismiss];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }];
}
@end
