// 
// Copyright 2013-2014 Yummy Melon Software LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Author: Charles Y. Choi <charles.choi@yummymelon.com>
//

#import "DEMBaseViewCell.h"
#import "DEMAccelerometerViewCell.h"
#import "DEASensorTag.h"
#import "DEAAccelerometerService.h"
#import "DEADeviceInfoService.h"
#import "YMSCBCharacteristic.h"

@implementation DEMAccelerometerViewCell

- (void)configureWithSensorTag:(DEASensorTag *)sensorTag {
    self.service = sensorTag.serviceDict[@"accelerometer"];
    
    for (NSString *key in @[@"x", @"y", @"z", @"isOn", @"isEnabled", @"period", @"tag_id"]) {
        [self.service addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew context:NULL];
    }
    if (self.service.isOn) {
        [self.notifySwitch setState:NSOnState];
    } else {
        [self.notifySwitch setState:NSOffState];
    }
    [self.notifySwitch setEnabled:self.service.isEnabled];
    
    
    self.periodSlider.enabled = self.service.isEnabled;
    
    DEAAccelerometerService *as = (DEAAccelerometerService *)self.service;
    if (as.isEnabled) {
        [as requestReadPeriod];
        //[as readSystemID];
    }
    
}

- (void)deconfigure {
    for (NSString *key in @[@"x", @"y", @"z", @"isOn", @"isEnabled", @"period", @"tag_id"]) {
        [self.service removeObserver:self forKeyPath:key];
    }
}


- (IBAction)periodSliderAction:(id)sender {
    
    uint8_t value;
    
    value = (uint8_t)[self.periodSlider integerValue];
    
    //NSLog(@"Value: %x", value);
    
    DEAAccelerometerService *as = (DEAAccelerometerService *)self.service;
    [as configPeriod:value];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (object != self.service) {
        return;
    }
    
    DEAAccelerometerService *as = (DEAAccelerometerService *)object;
    //NSString *AccDataPath = @"/Users/yuanda/Development/Workspaces/12Parsecs/20140403.csv";
   
    
    YMSCBService *sysService ;
    DEADeviceInfoService *is = (DEADeviceInfoService *)sysService;
    //YMSCBCharacteristic *system_id = is.characteristicDict[@"system_id"];
    
    //[is readDeviceInfo];
    //NSString *sys_id = [self.service valueForKey:@"tag_id"];
    NSString *sys_id = @"nullll";
    
    if ([keyPath isEqualToString:@"x"]) {
        self.accelXLabel.stringValue = [NSString stringWithFormat:@"%0.2f", [as.x floatValue]];
    } else if ([keyPath isEqualToString:@"y"]) {
        self.accelYLabel.stringValue = [NSString stringWithFormat:@"%0.2f", [as.y floatValue]];
    } else if ([keyPath isEqualToString:@"z"]) {
        self.accelZLabel.stringValue = [NSString stringWithFormat:@"%0.2f", [as.z floatValue]];
        NSString *AccData = [NSString stringWithFormat:@"ID:%@,%@,%@,%@", sys_id,self.accelXLabel.stringValue,self.accelYLabel.stringValue,self.accelZLabel.stringValue];
        NSLog(@"%@",AccData);
        //[self appendText:AccData toFile:AccDataPath];
    } else if ([keyPath isEqualToString:@"isOn"]) {
        if (as.isOn) {
            [self.notifySwitch setState:NSOnState];
        } else {
            [self.notifySwitch setState:NSOffState];
        }
    } else if ([keyPath isEqualToString:@"isEnabled"]) {
        [self.notifySwitch setEnabled:as.isEnabled];
        if (as.isEnabled) {
            self.periodSlider.enabled = as.isEnabled;
            [as requestReadPeriod];
        }
    
    } else if ([keyPath isEqualToString:@"period"]) {
        
        int pvalue = (int)([as.period floatValue] * 10.0);
        
        self.periodLabel.stringValue = [NSString stringWithFormat:@"%d ms", pvalue];
        [self.periodSlider setFloatValue:[as.period floatValue]];
    }
}


- (void)appendText:(NSString *)text toFile:(NSString *)filePath {
    
    // NSFileHandle won't create the file for us, so we need to check to make sure it exists
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) {
        
        // the file doesn't exist yet, so we can just write out the text using the
        // NSString convenience method
        
        NSError *error = noErr;
        BOOL success = [text writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (!success) {
            // handle the error
            NSLog(@"%@", error);
        }
        
    } else {
        
        // the file already exists, so we should append the text to the end
		
        // get a handle to the file
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
		
        // move to the end of the file
        [fileHandle seekToEndOfFile];
		
        // convert the string to an NSData object
        NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];
		
        // write the data to the end of the file
        [fileHandle writeData:textData];
		NSLog(@"Writing data to CSV");
        // clean up
        [fileHandle closeFile];
    }
}


@end
