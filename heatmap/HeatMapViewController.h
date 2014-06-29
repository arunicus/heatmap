//
//  HeatMapViewController.h
//  heatmap
//
//  Created by arun venkatesh on 6/27/14.
//  Copyright (c) 2014 tdameritrade. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TreemapView.h"

@interface HeatMapViewController : UIViewController <TreemapViewDelegate, TreemapViewDataSource,NSXMLParserDelegate,UIScrollViewDelegate>
@property (nonatomic, retain) NSMutableArray *fruits;
@property (nonatomic,strong) NSMutableDictionary *taHeatMap;
@end
