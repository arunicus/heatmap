//
//  HeatMapViewController.m
//  heatmap
//
//  Created by arun venkatesh on 6/27/14.
//  Copyright (c) 2014 tdameritrade. All rights reserved.
//

#import "HeatMapViewController.h"
#import "TreemapKit/TreemapView.h"

@interface HeatMapViewController ()
@property (weak, nonatomic) IBOutlet TreemapView *tree;
@property (strong,nonatomic) NSMutableDictionary *childTree;
@property (strong,nonatomic) NSMutableDictionary *parentTree;
@property (strong,nonatomic) NSMutableDictionary *indicesTree;
@end

@implementation HeatMapViewController

@synthesize fruits;
@synthesize taHeatMap;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tree.delegate= self;
    self.tree.dataSource = self;
	// Do any additional setup after loading the view, typically from a nib.
}

#pragma mark -
#pragma mark TreemapView data source

- (NSMutableArray *)valuesForTreemapView:(TreemapView *)treemapView {
	if (!fruits) {
		NSBundle *bundle = [NSBundle mainBundle];
		NSString *plistPath = [bundle pathForResource:@"data" ofType:@"plist"];
		NSArray *array = [[NSArray alloc] initWithContentsOfFile:plistPath];
        
		self.fruits = [[NSMutableArray alloc] initWithCapacity:array.count];
		for (NSDictionary *dic in array) {
			NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:dic];
			[fruits addObject:mDic];
		}
	}
    
	NSMutableArray *values = [NSMutableArray arrayWithCapacity:fruits.count];
	for (NSDictionary *dic in fruits) {
		[values addObject:[dic valueForKey:@"value"]];
	}
    
    if(!taHeatMap){
        taHeatMap = [[NSMutableDictionary alloc] init];
        self.parentTree = taHeatMap;
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *xmlPath = [bundle pathForResource:@"indicesPriceChgFlex" ofType:@"xml"];
        NSData *xmlData = [NSData dataWithContentsOfFile:xmlPath];
        NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:xmlData];
        xmlParser.delegate = self;
        [xmlParser parse];
        taHeatMap = [taHeatMap valueForKey:@"children"];
        NSLog(@" %@",taHeatMap);
    }
    NSMutableArray *valuesMap = [NSMutableArray arrayWithCapacity:taHeatMap.count];
    for(NSString *dic in taHeatMap){
        [valuesMap addObject:[[taHeatMap valueForKey:dic] valueForKey:@"weight"]];
    }
    
    NSMutableArray *nodes = [NSMutableArray arrayWithCapacity:taHeatMap.count];
    int i =0 ;
    for(NSString *key in taHeatMap){
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:3];
        [dic setValue:[NSNumber numberWithInt:i] forKey:@"index"];
        [dic setValue:key forKey:@"key"];
        [dic setValue:[[taHeatMap valueForKey:key] valueForKey:@"weight"] forKey:@"value"];
        self.childTree =[[taHeatMap valueForKey:key] valueForKey:@"children"];
        if(self.childTree){
            NSMutableArray *childnodes = [NSMutableArray arrayWithCapacity:self.childTree.count];
            for(NSString *childkey in self.childTree){
                NSMutableDictionary *childdic = [NSMutableDictionary dictionaryWithCapacity:3];
                [childdic setValue:[NSNumber numberWithInt:i] forKey:@"index"];
                [childdic setValue:childkey forKey:@"key"];
                [childdic setValue:[[self.childTree valueForKey:childkey] valueForKey:@"weight"] forKey:@"value"];
                [childnodes addObject:childdic];
            }
            [dic setValue:childnodes forKey:@"children"];
        }
        [nodes addObject:dic];
        i++;
    }

    return nodes;

}

- (TreemapViewCell *)treemapView:(TreemapView *)treemapView cellForIndex:(NSInteger)index forKey:(NSString *)key forRect:(CGRect)rect{
	TreemapViewCell *cell = [[TreemapViewCell alloc] initWithFrame:rect];
	[self updateCell:cell forIndex:index forKey:key ];
	return cell;
}

- (void)treemapView:(TreemapView *)treemapView updateCell:(TreemapViewCell *)cell forIndex:(NSInteger)index forKey:(NSString *)key forRect:(CGRect)rect {
	[self updateCell:cell forIndex:index forKey:key];
}



- (void)updateCell:(TreemapViewCell *)cell forIndex:(NSInteger)index forKey:(NSString *)key {
    NSLog(@" key %@,%ld, %@",key ,(long)index,[[taHeatMap valueForKey:key] valueForKey:@"weight"]);
    CGFloat alp = 0.2;
    if(![[taHeatMap valueForKey:key] valueForKey:@"weight"]){
        alp = 1;
        NSString *parentKey = taHeatMap.allKeys[index];
    NSLog(@" key %@,%ld, %@",key ,(long)index,[[[[taHeatMap valueForKey:parentKey] valueForKey:@"children"] valueForKey:key] valueForKey:@"value"]);
        CGFloat val = [[[[[taHeatMap valueForKey:parentKey] valueForKey:@"children"] valueForKey:key] valueForKey:@"value"] floatValue];
        if(val > 0){
            cell.backgroundColor = [UIColor colorWithRed:0 green:val blue:0 alpha:1];
        }else{
            val = val* -1;
            cell.backgroundColor = [UIColor colorWithRed:val green:0 blue:0 alpha:1];
        }
    }else{
        cell.backgroundColor = [UIColor colorWithHue:(float)index / (fruits.count + 3)
                                          saturation:1 brightness:0.75 alpha:alp];
    }
	cell.textLabel.text = key;
	cell.valueLabel.text = @"";
}



-(void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if(![elementName isEqualToString:@"indices"]){
        if([attributeDict valueForKey:@"weight"]){
//            NSLog(@" name %@",elementName);
//            NSLog(@" attributeDict %@",attributeDict);
            [self.childTree setValue:attributeDict forKeyPath:[attributeDict valueForKey:@"label"]];
            CGFloat total = [[attributeDict valueForKey:@"weight"] floatValue];
            total = total + [[self.parentTree valueForKey:@"weight"] floatValue];
            [self.parentTree setValue:[NSString stringWithFormat:@"%f",total] forKey:@"weight"];
            
        }else{
            if(![[attributeDict valueForKey:@"label"] isEqualToString:@"DOW JONES"]){
//                NSLog(@" parent %@",elementName);
//                NSLog(@" attributeDict %@",attributeDict);
                self.childTree = [[NSMutableDictionary alloc] init];
                self.parentTree = [[NSMutableDictionary alloc] init];
                
                [self.parentTree  setValue:self.childTree forKey:@"children"];
                [self.parentTree  addEntriesFromDictionary:attributeDict];
                [self.indicesTree setValue:self.parentTree forKey:[attributeDict valueForKey:@"label"]];
                [self.parentTree setValue:0  forKey:@"weight"];
            }else{
                self.indicesTree = [[NSMutableDictionary alloc] init];
                [taHeatMap addEntriesFromDictionary:attributeDict];
                [taHeatMap setValue:self.indicesTree forKey:@"children"];

            }
        }
        
    }
    
    
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    // resize rectangles with animation
    [UIView beginAnimations:@"reload" context:nil];
    [UIView setAnimationDuration:0.2];
    
    [(TreemapView *)self.tree reloadData];
    
    [UIView commitAnimations];
}


@end
