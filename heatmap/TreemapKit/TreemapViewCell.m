#import "TreemapView.h"
#import "TreemapViewCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation TreemapViewCell

@synthesize valueLabel;
@synthesize textLabel;
@synthesize index;
@synthesize delegate;

#pragma mark -

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.layer.borderWidth = 0.5;
        self.layer.borderColor = [[UIColor whiteColor] CGColor];

        self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        textLabel.font = [UIFont boldSystemFontOfSize:10];
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.textColor = [UIColor whiteColor];
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.adjustsFontSizeToFitWidth = YES;
        if(frame.size.width < frame.size.height){
            [textLabel setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
        }
        [self addSubview:textLabel];

//        self.valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width - 4, frame.size.height-4)];
//        valueLabel.font = [UIFont boldSystemFontOfSize:10];
//        valueLabel.textAlignment = NSTextAlignmentCenter;
//        valueLabel.textColor = [UIColor whiteColor];
//        valueLabel.backgroundColor = [UIColor clearColor];
//        valueLabel.adjustsFontSizeToFitWidth = YES;
//        if(frame.size.width < frame.size.height){
//            [valueLabel setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
//        }
        //[self addSubview:valueLabel];
    }
    return self;
}

-(void)drawRect:(CGRect)rect{
    if(self.frame.size.width < self.frame.size.height){
        textLabel.frame = CGRectMake( 0, 0, self.frame.size.width, self.frame.size.height);
    }else{
        textLabel.frame = CGRectMake(0,0, self.frame.size.width, self.frame.size.height);
    }
}



- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    if (delegate && [delegate respondsToSelector:@selector(treemapViewCell:tapped:)]) {
        [delegate treemapViewCell:self tapped:index];
    }
}

@end
