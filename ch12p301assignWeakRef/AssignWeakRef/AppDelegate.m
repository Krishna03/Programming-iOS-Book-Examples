
// illustrating why a non-ARC weak reference is dangerous (can be dangling pointer)
// but an ARC weak reference is not (nilified instead of dangling)

#import "AppDelegate.h"
#import "MyClass.h"

@implementation AppDelegate {
    MyClass* thing;
    id obj;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    UINavigationController* nav = [[UINavigationController alloc] init];
    self.window.rootViewController = nav;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    self->obj = [NSObject new];
    nav.delegate = obj;
    
    MyClass* m = [MyClass new];
    m.delegate = obj;
    self->thing = m;
    
    // added another log and numbers, to show when the log messages occur
    NSLog(@"MyClass delegate (1): %@", thing.delegate); // 
    NSLog(@"Nav Controller delegate (1): %@", thing.delegate); //
    
    [self performSelector:@selector(havoc) withObject:nil afterDelay:1.0];
    
    return YES;
}

- (void) havoc {
    // let slip the dogs of war
    self->obj = nil; // releases obj - now what is nav.delegate pointing to?
    
    NSLog(@"MyClass delegate (2): %@", thing.delegate); // perfectly safe, __weak ref is nilified
    
    NSLog(@"Nav Controller delegate (2): %@", ((UINavigationController*)self.window.rootViewController).delegate); // if you're lucky it might print something!
    // or more likely it will just crash, or maybe print and *then* crash
}


@end
