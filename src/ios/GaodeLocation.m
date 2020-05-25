/********* GaodeLocation.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import <Cordova/CDVCommandDelegate.h>
#import <AMapLocationKit/AMapLocationKit.h>
#import <AMapFoundationKit/AMapServices.h>

#define DefaultLocationTimeout  6
#define DefaultReGeocodeTimeout 3

@interface GaodeLocation : CDVPlugin<AMapLocationManagerDelegate> {
  // Member variables go here.
    CDVPluginResult* pluginResult;
    CDVInvokedUrlCommand* cmd;
}

@property (nonatomic, strong) AMapLocationManager *locationManager;
@property (nonatomic, copy) AMapLocatingCompletionBlock completionBlock;

- (void)getCurrentPosition:(CDVInvokedUrlCommand*)command;
@end

@implementation GaodeLocation

- (void)configureAPIKey
{
    [AMapServices sharedServices].apiKey = @"015720d09c969c73f15ae5e9ee5bf17f";
}

- (void)configLocationManager
{
    [self configureAPIKey];
    self.locationManager = [[AMapLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    //设置期望定位精度
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    //设置不允许系统暂停定位
    [self.locationManager setPausesLocationUpdatesAutomatically:NO];
    //设置允许在后台定位
    //[self.locationManager setAllowsBackgroundLocationUpdates:YES];
    //设置定位超时时间
    [self.locationManager setLocationTimeout:DefaultLocationTimeout];
    //设置逆地理超时时间
    [self.locationManager setReGeocodeTimeout:DefaultReGeocodeTimeout];
}

- (void)cleanUpAction
{
    //停止定位
    [self.locationManager stopUpdatingLocation];
    
    [self.locationManager setDelegate:nil];
    
}

- (void)reGeocodeAction
{
    //进行单次带逆地理定位请求
    [self.locationManager requestLocationWithReGeocode:YES completionBlock:self.completionBlock];
}

- (void)locAction
{
    //进行单次定位请求
    [self.locationManager requestLocationWithReGeocode:NO completionBlock:self.completionBlock];
}

#pragma mark - Initialization

- (void)initCompleteBlock
{
    self.completionBlock = ^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error)
    {
        pluginResult = nil;
        NSMutableDictionary* jsonDict = [[NSMutableDictionary alloc] init];
        
        if (error != nil && error.code == AMapLocationErrorLocateFailed)
        {
            //定位错误：此时location和regeocode没有返回值，不进行annotation的添加
            //NSLog(@"定位错误:{%ld - %@};", (long)error.code, error.localizedDescription);
            [jsonDict setValue:@"定位失败" forKey:@"status"];
            [jsonDict setValue:[NSString stringWithFormat:@"%ld", (long)error.code] forKey:@"errcode"];
            [jsonDict setValue:error.localizedDescription forKey:@"errinfo"];
            [jsonDict setValue:error.description forKey:@"detail"];
            
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:jsonDict];
            return;
        }
        else if (error != nil
                 && (error.code == AMapLocationErrorReGeocodeFailed
                     || error.code == AMapLocationErrorTimeOut
                     || error.code == AMapLocationErrorCannotFindHost
                     || error.code == AMapLocationErrorBadURL
                     || error.code == AMapLocationErrorNotConnectedToInternet
                     || error.code == AMapLocationErrorCannotConnectToHost))
        {
            //逆地理错误：在带逆地理的单次定位中，逆地理过程可能发生错误，此时location有返回值，regeocode无返回值
            //pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
            //NSLog(@"逆地理错误:{%ld - %@};", (long)error.code, error.localizedDescription);
            [jsonDict setValue:@"定位失败" forKey:@"status"];
            [jsonDict setValue:[NSString stringWithFormat:@"%ld", (long)error.code] forKey:@"errcode"];
            [jsonDict setValue:error.localizedDescription forKey:@"errinfo"];
            [jsonDict setValue:error.description forKey:@"detail"];
            
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:jsonDict];

        }
        else
        {
            //没有错误：location有返回值，regeocode是否有返回值取决于是否进行逆地理操作
            //NSLog(@"location ok");
            
            
            //NSLog(@"%@", [NSString stringWithFormat:@"%f", location.coordinate.longitude]);
            [jsonDict setValue:@"定位成功" forKey:@"status"];
            [jsonDict setValue:@"GPS" forKey:@"type"];
            [jsonDict setValue:[NSString stringWithFormat:@"%lf", location.coordinate.latitude] forKey:@"latitude"];
            [jsonDict setValue:[NSString stringWithFormat:@"%lf", location.coordinate.longitude] forKey:@"longitude"];
            [jsonDict setValue:[NSString stringWithFormat:@"%lf", location.horizontalAccuracy] forKey:@"accuracy"];
            [jsonDict setValue:@"" forKey:@"bearing"];
            [jsonDict setValue:@"" forKey:@"satellites"];
            [jsonDict setValue:regeocode.country forKey:@"country"];
            [jsonDict setValue:regeocode.province forKey:@"province"];
            [jsonDict setValue:regeocode.city forKey:@"city"];
            [jsonDict setValue:regeocode.citycode forKey:@"citycode"];
            [jsonDict setValue:regeocode.district forKey:@"district"];
            [jsonDict setValue:regeocode.adcode forKey:@"adcode"];
            [jsonDict setValue:regeocode.street forKey:@"street"];
            [jsonDict setValue:regeocode.formattedAddress forKey:@"address"];
            [jsonDict setValue:regeocode.POIName forKey:@"poi"];
            //[jsonDict setValue:location.timestamp forKey:@"time"];

            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:jsonDict];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:cmd.callbackId];
    };
}

- (void)getCurrentPosition:(CDVInvokedUrlCommand*)command
{
    cmd = command;
    [self cleanUpAction];
    [self configLocationManager];
    [self initCompleteBlock];
    [self reGeocodeAction];
}

@end
