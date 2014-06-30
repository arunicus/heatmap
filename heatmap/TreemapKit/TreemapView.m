#import "TreemapView.h"

@implementation TreemapView

@synthesize dataSource;
@synthesize delegate;

#pragma mark -
#pragma mark NSObject

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        initialized = NO;
    }

    return self;
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipe {
    
    if (swipe.direction == UISwipeGestureRecognizerDirectionLeft) {
        NSLog(@"Left Swipe");
        [self treemapViewCell:nil tapped:-1];
    }
    
    if (swipe.direction == UISwipeGestureRecognizerDirectionRight) {
        NSLog(@"Right Swipe");
    }
    
}

- (void)drawRect:(CGRect)rect {
    if (!initialized) {
        [self createNodes];
        initialized = YES;
        UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        
        // Setting the swipe direction.
        [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
        [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
        
        // Adding the swipe gesture on tree view
        [self addGestureRecognizer:swipeLeft];
        [self addGestureRecognizer:swipeRight];
    }
    
}

- (NSArray *)getData {
    NSMutableArray *values = [dataSource valuesForTreemapView:self];
    return values;
}

- (void)createNodes {
    NSArray *nodes = [self getData];
    if (nodes && nodes.count > 0) {
        [self calcNodePositions:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)
                          nodes:nodes
                          width:ceil(self.bounds.size.width)
                         height:ceil(self.bounds.size.height)
                          depth:0
                     withCreate:YES];
    }
}

- (void)resizeNodes {
    [self removeNodes];
    NSArray *nodes = [self getData];
    if (nodes && nodes.count > 0) {
        [self calcNodePositions:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)
                          nodes:nodes
                          width:ceil(self.bounds.size.width)
                         height:ceil(self.bounds.size.height)
                          depth:0
                     withCreate:YES];       
    }
}

- (void)removeNodes {
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
}


- (void)calcNodePositions:(CGRect)rect nodes:(NSArray *)nodes width:(CGFloat)width height:(CGFloat)height depth:(NSInteger)depth withCreate:(BOOL)createNode {
    if (nodes.count <= 1) {
        NSInteger index = [[[nodes objectAtIndex:0] valueForKey:@"index"] integerValue];
        if (createNode || index >= self.subviews.count) {
            TreemapViewCell *cell = [dataSource treemapView:self cellForIndex:index forKey:[[nodes objectAtIndex:0] valueForKey:@"key"] forRect:rect];
            cell.index = index;
            cell.delegate = self;

            if([[nodes objectAtIndex:0] valueForKey:@"children"]){
                NSArray *childrenArray =[[nodes objectAtIndex:0] valueForKey:@"children"];
                [self calcNodePositions:rect nodes:childrenArray width:rect.size.width height:rect.size.height depth:depth + 1 withCreate:createNode];
            }
            [self addSubview:cell];
            
        }else {
            TreemapViewCell *cell = [self.subviews objectAtIndex:index];
            cell.frame = rect;
            if ([delegate respondsToSelector:@selector(treemapView:updateCell:forIndex:forKey:forRect:)])
                [delegate treemapView:self updateCell:cell forIndex:index forKey:[[nodes objectAtIndex:0] valueForKey:@"label"] forRect:rect];
            [cell layoutSubviews];
        }
        return;
    }

    CGFloat total = 0;
    for (NSDictionary *dic in nodes) {
        total += [[dic objectForKey:@"value"] floatValue];
    }
    CGFloat half = total / 2.0;

    NSInteger customSep = NSNotFound;
    if ([dataSource respondsToSelector:@selector(treemapView:separationPositionForDepth:)])
        customSep = [dataSource treemapView:self separationPositionForDepth:depth];

    NSInteger m;
    if (customSep != NSNotFound) {
        m = customSep;
    }
    else {
        m = nodes.count - 1;
        total = 0.0;
        for (NSInteger i = 0; i < nodes.count; i++) {
            if (total > half) {
                m = i;
                break;
            }
            total += [[[nodes objectAtIndex:i] objectForKey:@"value"] floatValue];
        }
        if (m < 1) m = 1;
    }

    NSArray *aArray = [nodes subarrayWithRange:NSMakeRange(0, m)];
    NSArray *bArray = [nodes subarrayWithRange:NSMakeRange(m, nodes.count - m)];

    CGFloat aTotal = 0.0;
    for (NSDictionary *dic in aArray) {
        aTotal += [[dic objectForKey:@"value"] floatValue];
    }
    CGFloat bTotal = 0.0;
    for (NSDictionary *dic in bArray) {
        bTotal += [[dic objectForKey:@"value"] floatValue];
    }

    CGFloat aRatio;
    if (aTotal + bTotal > 0.0)
        aRatio = aTotal / (aTotal + bTotal);
    else
        aRatio = 0.5;

    CGRect aRect, bRect;
    CGFloat aWidth, aHeight, bWidth, bHeight;

    BOOL horizontal = (width > height);

    CGFloat sep = 0.0;
    if ([dataSource respondsToSelector:@selector(treemapView:separatorWidthForDepth:)])
        sep = [dataSource treemapView:self separatorWidthForDepth:depth];

    if (horizontal) {
        aWidth = ceil((width - sep) * aRatio);
        bWidth = width - sep - aWidth;
        aHeight = bHeight = height;
        aRect = CGRectMake(rect.origin.x, rect.origin.y, aWidth, aHeight);
        bRect = CGRectMake(rect.origin.x + aWidth + sep, rect.origin.y, bWidth, bHeight);
    }
    else { // vertical layout
        if (total == 0.0) {
            aWidth = aHeight = bWidth = bHeight = 0.0;
            aRect = CGRectMake(rect.origin.x, rect.origin.y, 0.0, 0.0);
            bRect = CGRectMake(rect.origin.x, rect.origin.y + sep, 0.0, 0.0);
        }
        else {
            aWidth = bWidth = width;
            aHeight = ceil((height - sep) * aRatio);
            bHeight = height - sep - aHeight;
            aRect = CGRectMake(rect.origin.x, rect.origin.y, aWidth, aHeight);
            bRect = CGRectMake(rect.origin.x, rect.origin.y + aHeight + sep, bWidth, bHeight);
        }
    }

    [self calcNodePositions:aRect nodes:aArray width:aWidth height:aHeight depth:depth + 1 withCreate:createNode];
    [self calcNodePositions:bRect nodes:bArray width:bWidth height:bHeight depth:depth + 1 withCreate:createNode];
}


#pragma mark -
#pragma mark Public methods

- (void)reloadData {
    [self resizeNodes];
}


//#pragma mark -
//#pragma mark TreemapViewCell delegate
//
//- (void)treemapViewCell:(TreemapViewCell *)treemapViewCell
//           touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    if (delegate && [delegate respondsToSelector:@selector(treemapView:touchesBegan:withEvent:)]) {
//        [delegate treemapView:self touchesBegan:touches withEvent:event];
//    }
//}
//
//- (void)treemapViewCell:(TreemapViewCell *)treemapViewCell
//       touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
//    if (delegate && [delegate respondsToSelector:@selector(treemapView:touchesCancelled:withEvent:)]) {
//        [delegate treemapView:self touchesCancelled:touches withEvent:event];
//    }
//}
//
//- (void)treemapViewCell:(TreemapViewCell *)treemapViewCell
//           touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//    if (delegate && [delegate respondsToSelector:@selector(treemapView:touchesEnded:withEvent:)]) {
//        [delegate treemapView:self touchesEnded:touches withEvent:event];
//    }
//}
//
//- (void)treemapViewCell:(TreemapViewCell *)treemapViewCell
//           touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    if (delegate && [delegate respondsToSelector:@selector(treemapView:touchesMoved:withEvent:)]) {
//        [delegate treemapView:self touchesMoved:touches withEvent:event];
//    }
//}
//
- (void)treemapViewCell:(TreemapViewCell *)treemapViewCell tapped:(NSInteger)index {
    if (delegate && [delegate respondsToSelector:@selector(treemapView:tapped:)]) {
        [delegate treemapView:self tapped:index];
    }
}

//#pragma mark -
//#pragma mark UIView
//
//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    if (delegate && [delegate respondsToSelector:@selector(treemapView:touchesBegan:withEvent:)]) {
//        [delegate treemapView:self touchesBegan:touches withEvent:event];
//    }
//}
//
//- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
//    if (delegate && [delegate respondsToSelector:@selector(treemapView:touchesCancelled:withEvent:)]) {
//        [delegate treemapView:self touchesCancelled:touches withEvent:event];
//    }
//}
//
//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//    if (delegate && [delegate respondsToSelector:@selector(treemapView:touchesEnded:withEvent:)]) {
//        [delegate treemapView:self touchesEnded:touches withEvent:event];
//    }
//}
//
//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    if (delegate && [delegate respondsToSelector:@selector(treemapView:touchesMoved:withEvent:)]) {
//        [delegate treemapView:self touchesMoved:touches withEvent:event];
//    }
//}



@end
