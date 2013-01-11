//
//  CFShareCircleView.m
//  CFShareCircle
//
//  Created by Camden on 12/18/12.
//  Copyright (c) 2012 Camden. All rights reserved.
//

#import "CFShareCircleView.h"

@implementation CFShareCircleView

@synthesize delegate;
@synthesize imageNames = _imageNames;

-(id)init{
    self = [super initWithFrame:CGRectMake(0, 0, 320, 480)];
    if (self) {
        [self initialize];
        [self setImageNames:[[NSArray alloc] initWithObjects:@"evernote.png", @"facebook.png", @"googleplus.png", @"twitter.png", @"flickr.png", @"photo_album.png", @"email.png", nil]];
        [self setUpLayers];
        [self setViewFrame];
    }
    return self;
}

- (id)initWithCustomImageNames: (NSArray*)images{
    self = [super initWithFrame:CGRectMake(0, 0, 320, 480)];
    if (self) {
        [self initialize];
        [self setImageNames:images];
        [self setUpLayers];
        [self setViewFrame];
    }
    return self;
}

/* Set all the default values for the share circle. */
- (void)initialize{
    
    imageLayers = [[NSMutableArray alloc] init];
    
    self.hidden = YES;
    self.backgroundColor = [UIColor clearColor];
    self.bounds = CGRectMake(0, 0, 320,480);
    origin = CGPointMake(160, 240);
    currentPosition = origin;
    visible = NO;
    currentOrientation = [[UIDevice currentDevice] orientation];
    
    // Create shadow for UIView.
    self.layer.masksToBounds = NO;
    self.layer.shadowOffset = CGSizeMake(0, 0);
    self.layer.shadowRadius = 5;
    self.layer.shadowOpacity = 0.5;
    
    // Set up observer for orientation changes.
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(deviceOrientationDidChange:) name: UIDeviceOrientationDidChangeNotification object: nil];
}

/* Build all the layers to be displayed onto the view of the share circle. */
- (void)setUpLayers{
    
    // Create a larger circle layer for the background of the Share Circle.
    backgroundLayer = [CAShapeLayer layer];
    backgroundLayer.bounds = self.bounds;
    backgroundLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    backgroundLayer.fillColor = [[UIColor whiteColor] CGColor];
    CGMutablePathRef backgroundPath = CGPathCreateMutable();
    CGRect backgroundRect = CGRectMake(origin.x - BACKGROUND_SIZE/2,origin.y - BACKGROUND_SIZE/2,BACKGROUND_SIZE,BACKGROUND_SIZE);
    CGPathAddEllipseInRect(backgroundPath, nil, backgroundRect);
    backgroundLayer.path = backgroundPath;
    [self.layer addSublayer:backgroundLayer];
    
    
    // Create the close button layer for the Share Circle.
    closeButtonLayer = [CAShapeLayer layer];
    closeButtonLayer.bounds = self.bounds;
    closeButtonLayer.contents = (id) [UIImage imageNamed:@"close_button.png"].CGImage;
    
    // Create the rect and the point to draw the image.
    // Calculate the x and y coordinate at pi/4.
    double x = origin.x - CLOSE_BUTTON_SIZE/2.0 + cosf(M_PI/4)*BACKGROUND_SIZE/2.0;
    double y = origin.y - CLOSE_BUTTON_SIZE/2.0 - sinf(M_PI/4)*BACKGROUND_SIZE/2.0;
    
    CGRect tempRect = CGRectMake(x,y - 10,CLOSE_BUTTON_SIZE,CLOSE_BUTTON_SIZE);
    closeButtonLayer.frame = tempRect;
    
    // Create the overlay for the button
    CAShapeLayer *overlayLayer = [CAShapeLayer layer];
    overlayLayer.bounds = closeButtonLayer.frame;
    overlayLayer.frame = closeButtonLayer.frame;
    //overlayLayer.position = );
    overlayLayer.fillColor = [[UIColor whiteColor] CGColor];
    overlayLayer.opacity = 0.2;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddEllipseInRect(path, nil, CGRectMake(0, 0, 40, 40));
    overlayLayer.path = path;
    
    [backgroundLayer addSublayer:closeButtonLayer];
    [closeButtonLayer addSublayer:overlayLayer];
    
    
    // Create the layers for all the sharing service images.
    for(int i = 0; i < _imageNames.count; i++) {
        UIImage *image = [UIImage imageNamed:[_imageNames objectAtIndex:i]];
        // Construct the base layer in which will be rotated around the origin of the circle.
        CAShapeLayer *baseLayer = [CAShapeLayer layer];
        baseLayer.bounds = CGRectMake(0,0, BACKGROUND_SIZE,BACKGROUND_SIZE);
        baseLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        // Construct the image layer which will contain our image.
        CALayer *imageLayer = [CALayer layer];
        imageLayer.bounds = CGRectMake(0, 0, TEMP_SIZE, TEMP_SIZE);
        imageLayer.position = CGPointMake(BACKGROUND_SIZE/2.0 + PATH_SIZE/2.0, BACKGROUND_SIZE/2.0);
        imageLayer.contents = (id)image.CGImage;
        // Add all the layers
        [baseLayer addSublayer:imageLayer];
        [imageLayers addObject:baseLayer];
        [self.layer addSublayer:[imageLayers objectAtIndex:i]];
    }
    
    
    // Create the touch layer for the Share Circle.
    touchLayer = [CAShapeLayer layer];
    touchLayer.bounds = self.bounds;
    touchLayer.frame = CGRectMake(0, 0, TOUCH_SIZE, TOUCH_SIZE);
    touchLayer.contents = (id) [UIImage imageNamed:@"touch.png"].CGImage;
    touchLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    touchLayer.opacity = 0.4;
    [self.layer addSublayer:touchLayer];
    
    // Create the intro text layer to help the user.
    textLayer = [CATextLayer layer];
    textLayer.string = @"Drag and Share";
    textLayer.wrapped = YES;
    textLayer.alignmentMode = kCAAlignmentCenter;
    textLayer.fontSize = 13.0;
    textLayer.bounds = self.bounds;
    textLayer.foregroundColor = [UIColor blackColor].CGColor;
    textLayer.frame = CGRectMake(0, 0, 60, 29);
    textLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    textLayer.contentsScale = [[UIScreen mainScreen] scale];
    textLayer.opacity = 0.5;
    [self.layer addSublayer:textLayer];
}

/**
 TOUCH METHODS FOR GETTING USER INPUT
 **/

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = (UITouch *)[[touches allObjects] objectAtIndex:0];
    currentPosition = [touch locationInView:self];
    
    // Make sure the user starts with touch inside the circle and not in the close button.
    if([self circleEnclosesPoint: currentPosition] && ![self closeButtonEnclosesPoint:currentPosition]){
        dragging = YES;
        [self updateTouchPosition];
        [self updateImages];
    } else if( [self closeButtonEnclosesPoint:currentPosition]){
        // Hide close button overlay.
        CALayer *layer = [closeButtonLayer.sublayers objectAtIndex:0];
        layer.opacity = 0.0;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = (UITouch *)[[touches allObjects] objectAtIndex:0];
    currentPosition = [touch locationInView:self];
    
    if(dragging){
        [self updateTouchPosition];
        [self updateImages];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = (UITouch *)[[touches allObjects] objectAtIndex:0];
    currentPosition = [touch locationInView:self];
    
    // Show close button overlay.
    CALayer *layer = [closeButtonLayer.sublayers objectAtIndex:0];
    layer.opacity = 0.2;
    
    
    if(dragging){
        // Loop through all the rects to see if the user selected one.
        for(int i = 0; i < [_imageNames count]; i++){
            CGPoint point = [self pointAtIndex:i];
            // Determine if point is inside rect.
            if(CGRectContainsPoint(CGRectMake(point.x, point.y, TEMP_SIZE, TEMP_SIZE), currentPosition))
                [self.delegate shareCircleView:self didSelectIndex:i];
        }
    } else if([self closeButtonEnclosesPoint: currentPosition]){
        [self.delegate shareCircleViewWasCanceled];
    }
    
    currentPosition = origin;
    dragging = NO;
    [self updateTouchPosition];
    [self updateImages];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    // Reset location.
    currentPosition = origin;
    dragging = NO;
}

/**
 ANIMATION METHODS
 **/

/* Animates the whole view into the screen. */
- (void) animateIn{
    visible = YES;
    self.hidden = NO;
    textLayer.opacity = 0.5;
    
    [UIView animateWithDuration: 0.2
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self setViewFrame];
                     }
                     completion:^(BOOL finished){
                         [self animateImagesIn];
                     }];
}

/* Animates the whole view out of the screen. */
- (void) animateOut{
    visible = NO;
    [self animateImagesOut];
    [UIView animateWithDuration: 0.2
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self setViewFrame];
                     }
                     completion:^(BOOL finished){
                         self.hidden = YES;
                     }];
}

/* Moves the touch layer to the proper position when the user is interacting with the view. */
- (void) updateTouchPosition{
    [CATransaction begin];
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    // Update the position of the touch layer.
    touchLayer.position = [self touchLocationAtPoint:currentPosition];
    
    // Show a hover state when dragging, which will also show the text layer when not dragging.
    if(dragging){
        touchLayer.opacity = 1.0;
        textLayer.opacity = 0.0;
    }
    else{
        touchLayer.opacity = 0.4;
        textLayer.opacity = 0.6;
    }
    [CATransaction commit];
}

/* Upadtes the opacity of the images that are hovered over by the user. */
- (void) updateImages{
    for(int i = 0; i < [_imageNames count]; i++){
        CGPoint point = [self pointAtIndex:i];
        // Determine if point is inside rect.
        CALayer *layer = [imageLayers objectAtIndex:i];
        if(CGRectContainsPoint(CGRectMake(point.x, point.y, TEMP_SIZE, TEMP_SIZE), currentPosition) || !dragging)
            layer.opacity = 1;
        else
            layer.opacity = 0.6;
    }
}

/* Animation used when the view is first presented to the user. */
- (void) animateImagesIn{
    for(int i = 0; i < _imageNames.count; i++) {
        // Animate the base layer for the main rotation.
        CALayer* layer = [imageLayers objectAtIndex:i];
        layer.transform = CATransform3DMakeRotation(-i/([_imageNames count]/2.0)*M_PI, 0, 0, 1);
        layer.opacity = 1.0;
        
        // Animate the iamge layer to get the correct orientation.
        CALayer* sub = [layer.sublayers objectAtIndex:0];
        sub.transform = CATransform3DMakeRotation(i/([_imageNames count]/2.0)*M_PI, 0, 0, 1);
    }
}

/* Animation used to reset the images so the animation in works correctly. */
- (void) animateImagesOut{
    for(int i = 0; i < _imageNames.count; i++) {
        // Animate the base layer for the main rotation.
        CALayer* layer = [imageLayers objectAtIndex:i];
        layer.transform = CATransform3DMakeRotation(0, 0, 0, 1);
        
        // Animate the iamge layer to get the correct orientation.
        CALayer* sub = [layer.sublayers objectAtIndex:0];
        sub.transform = CATransform3DMakeRotation(0, 0, 0, 1);
    }
}

/**
 HELPER METHODS
 **/

/* Determines where the touch images is going to be placed inside of the view. */
- (CGPoint) touchLocationAtPoint:(CGPoint)point{
    
    // If not dragging make sure we redraw the touch image at the origin.
    if(!dragging)
        point = origin;
    
    // See if the new point is outside of the circle's radius.
    if(pow(BACKGROUND_SIZE/2.0 - TOUCH_SIZE/2.0,2) < (pow(point.x - origin.x,2) + pow(point.y - origin.y,2))){
        
        // Determine x and y from the center of the circle.
        point.x = origin.x - point.x;
        point.y -= origin.y;
        
        // Calculate the angle on the around the circle.
        double angle = atan2(point.y, point.x);
        
        // Get the new x and y from the point on the edge of the circle subtracting the size of the touch image.
        point.x = origin.x - (BACKGROUND_SIZE/2.0 - TOUCH_SIZE/2.0) * cos(angle);
        point.y = origin.y + (BACKGROUND_SIZE/2.0 - TOUCH_SIZE/2.0) * sin(angle);
    }
    
    return point;
}

/* Get the point at the specified index. */
- (CGPoint) pointAtIndex:(int) index{
    // Number for trig.
    float trig = index/([_imageNames count]/2.0)*M_PI;
    
    // Calculate the x and y coordinate.
    // Points go around the unit circle starting at pi = 0.
    float x = origin.x + cosf(trig)*PATH_SIZE/2.0;
    float y = origin.y - sinf(trig)*PATH_SIZE/2.0;
    
    // Subtract half width and height of image size.
    x -= TEMP_SIZE/2.0;
    y -= TEMP_SIZE/2.0;
    
    return CGPointMake(x, y);
}

/* Helper method to determine if a specified point is inside the circle. */
- (BOOL) circleEnclosesPoint: (CGPoint) point{
    if(pow(BACKGROUND_SIZE/2.0,2) < (pow(point.x - origin.x,2) + pow(point.y - origin.y,2)))
        return NO;
    else
        return YES;
}

/* Helper method to determine if a specified point is inside the close button. */
- (BOOL) closeButtonEnclosesPoint: (CGPoint) point{
    float x = origin.x - CLOSE_BUTTON_SIZE/2.0 + cosf(M_PI/4)*BACKGROUND_SIZE/2.0;
    float y = origin.y - CLOSE_BUTTON_SIZE/2.0 - sinf(M_PI/4)*BACKGROUND_SIZE/2.0;
    
    CGRect tempRect = CGRectMake(x,y,CLOSE_BUTTON_SIZE,CLOSE_BUTTON_SIZE);
    
    if(CGRectContainsPoint(tempRect, point))
        return YES;
    else
        return NO;
}

/* Determine the frame that the view is to use based on orientation. */
- (void) setViewFrame{
    
    if(UIDeviceOrientationIsPortrait(currentOrientation)){
        [self setFrame:CGRectMake(320*!visible, 0, 320, 480)];
        [self setBounds:CGRectMake(0, 0, 320, 480)];
        origin = CGPointMake(160, 240);
        currentPosition = origin;
    }else if(UIDeviceOrientationIsLandscape(currentOrientation)){
        [self setFrame:CGRectMake(480*!visible, 0, 480, 320)];
        [self setBounds:CGRectMake(0, 0, 480, 320)];
        origin = CGPointMake(240, 160);
        currentPosition = origin;
    }
    
    // Update all the layers positions.
    backgroundLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    textLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    [self updateTouchPosition];
    for(int i = 0; i < _imageNames.count; i++) {
        CALayer* layer = [imageLayers objectAtIndex:i];
        layer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    }
}

/**
 ORIENTATION CHANGE
 **/

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    //Obtaining the current device orientation
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    //Ignoring specific orientations
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown || currentOrientation == orientation) {
        return;
    }
    
    if ((UIDeviceOrientationIsPortrait(currentOrientation) && UIDeviceOrientationIsPortrait(orientation)) ||
        (UIDeviceOrientationIsLandscape(currentOrientation) && UIDeviceOrientationIsLandscape(orientation))) {
        //still saving the current orientation
        currentOrientation = orientation;
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(relayoutLayers) object:nil];
    //Responding only to changes in landscape or portrait
    currentOrientation = orientation;
    //
    [self performSelector:@selector(setViewFrame) withObject:nil afterDelay:0];
}

@end
