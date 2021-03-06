

#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

@implementation AppDelegate {
    __weak CADisplayLink* _link; // for example 5
    CIFilter* _tran; // for example 5
    CGRect moiextent; // for example 5, get extent in advance
    double _frame;
    
    UIImageView* iv;

    CIContext* con; // generate once early, as they are expensive and time-consuming to make

}


#define which 5 // or 2 for non-Core Image
// new in iOS 6! see 3 (mask), 4 (tile)
// iOS 6 can now also do transition filters; should try to illustrate this in the animations chapter
// try 5 to see it

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [UIViewController new];
    // Override point for customization after application launch.
    
    
    UIImage* moi = [UIImage imageNamed:@"moi.jpg"];
    self->iv = [[UIImageView alloc] initWithImage:moi]; // just to get started
    self->iv.backgroundColor = [UIColor blackColor];
    [self.window.rootViewController.view addSubview: self->iv];
    self->iv.center = self.window.center;
    
    self->con = [CIContext contextWithOptions:nil];

    CIImage* moi2 = [[CIImage alloc] initWithCGImage:moi.CGImage];
    moiextent = moi2.extent;
    UIImage* moi4;
    
    switch (which) {
        case 1: {
            
            CIFilter* grad = [CIFilter filterWithName:@"CIRadialGradient"];
            CIVector* center = [CIVector vectorWithX:moi.size.width/2.0 Y:moi.size.height/2.0];
            [grad setValue:center forKey:@"inputCenter"];
            CIFilter* dark = [CIFilter filterWithName:@"CIDarkenBlendMode"
                                        keysAndValues:
                              @"inputImage", grad.outputImage,
                              @"inputBackgroundImage", moi2,
                              nil];
            
            CGImageRef moi3 = [self->con createCGImage:dark.outputImage
                                        fromRect:moi2.extent];
            moi4 = [UIImage imageWithCGImage:moi3];
            CGImageRelease(moi3);
            
            break;
        }
        case 3: { // new in iOS 6, we have masking operations in CIFilter
            // this allows us to do the same sort of thing in a much snazzier way
            // instead of painting black on top, we put a color behind and mask to it
            
            CIFilter* col = [CIFilter filterWithName:@"CIConstantColorGenerator"];
            CIColor* cicol = [[CIColor alloc] initWithColor:[UIColor redColor]];
            [col setValue:cicol forKey:@"inputColor"];
            CIImage* colorimage = [col valueForKey: @"outputImage"];
            
            CIFilter* grad = [CIFilter filterWithName:@"CIRadialGradient"];
            CIVector* center = [CIVector vectorWithX:moi.size.width/2.0 Y:moi.size.height/2.0];
            [grad setValue:center forKey:@"inputCenter"];
            [grad setValue:@75 forKey:@"inputRadius0"];
            CIImage *gradimage = [grad valueForKey: @"outputImage"];

            CIFilter* blend = [CIFilter filterWithName:@"CIBlendWithMask"];
            [blend setValue:moi2 forKey:@"inputImage"];
            [blend setValue:colorimage forKey:@"inputBackgroundImage"];
            [blend setValue:gradimage forKey:@"inputMaskImage"];
            
            CGImageRef moi3 = [self->con createCGImage:blend.outputImage
                                        fromRect:moi2.extent];
            moi4 = [UIImage imageWithCGImage:moi3];
            CGImageRelease(moi3);
            break;
        }
        case 4: { // iOS 6 also lets us do some fun tiling effects
            CIFilter* tile = [CIFilter filterWithName:@"CIFourfoldRotatedTile"];
            [tile setValue:moi2 forKey:@"inputImage"];
            CIVector* center = [CIVector vectorWithX:moi.size.width/2.0-60 Y:moi.size.height/2.0-70];
            [tile setValue:center forKey:@"inputCenter"];
            
            CGImageRef moi3 = [self->con createCGImage:tile.outputImage
                                        fromRect:moi2.extent];
            moi4 = [UIImage imageWithCGImage:moi3];
            CGImageRelease(moi3);

            break;
        }
        case 5: {
            CIFilter* col = [CIFilter filterWithName:@"CIConstantColorGenerator"];
            CIColor* cicol = [[CIColor alloc] initWithColor:[UIColor redColor]];
            [col setValue:cicol forKey:@"inputColor"];
            CIImage* colorimage = [col valueForKey: @"outputImage"];

            CIFilter* tran = [CIFilter filterWithName:@"CIFlashTransition"];
            [tran setValue:colorimage forKey:@"inputImage"];
            [tran setValue:moi2 forKey:@"inputTargetImage"];
            CIVector* center = [CIVector vectorWithX:moi.size.width/2.0 Y:moi.size.height/2.0];
            [tran setValue:center forKey:@"inputCenter"];
            
            self->_tran = tran;
            self->_link = [CADisplayLink displayLinkWithTarget:self selector:@selector(nextFrame:)];
            [self->_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];

            break;
        }
        case 2: {
            UIGraphicsBeginImageContextWithOptions(moi.size, YES, 0);
            CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
            CFArrayRef arr = (__bridge CFArrayRef)@[
                (id)[UIColor whiteColor].CGColor,
                (id)([UIColor blackColor].CGColor)
            ];
            CGFloat locs[] = {0, .9};
            CGGradientRef grad = CGGradientCreateWithColors(space, arr, locs);
            CGColorSpaceRelease(space);
            CGContextDrawRadialGradient(UIGraphicsGetCurrentContext(), grad,
                                        CGPointMake(moi.size.width/2.0, moi.size.height/2.0),
                                        0,
                                        CGPointMake(moi.size.width/2.0, moi.size.height/2.0),
                                        moi.size.width/2.0,
                                        kCGGradientDrawsBeforeStartLocation);
            CGGradientRelease(grad);
            UIImage* gradimage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            UIGraphicsBeginImageContextWithOptions(moi.size, YES, 0);
            [moi drawAtPoint:CGPointZero];
            [gradimage drawAtPoint:CGPointZero blendMode:kCGBlendModeDarken alpha:1.0];
            moi4 = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            break;
        }
    }
    
    self->iv.image = moi4;
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void) nextFrame: (CADisplayLink*) sender {


    [_tran setValue:@(_frame) forKey:@"inputTime"];
    CGImageRef moi3 = [self->con createCGImage:_tran.outputImage
                                fromRect:moiextent];
    self->iv.image = [UIImage imageWithCGImage:moi3];
    CGImageRelease(moi3);
    
    _frame += sender.duration;
    
    if (_frame > 1.05 + sender.duration) { // play safe
        [sender invalidate];
        _frame = 0.0;
    }
    
    // NSLog(@"here %f", frame);
    

}

@end
