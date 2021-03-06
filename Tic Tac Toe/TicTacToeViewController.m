//
//  ViewController.m
//  Tic Tac Toe
//
//  Created by Jonathan Collins on 12/8/17.
//  Copyright © 2017 JC. All rights reserved.
//

#import "TicTacToeViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "TicTacToeConstants.h"
#import "TicTacToeButton.h"

@interface TicTacToeViewController ()
    //MARK: Properties
    @property BOOL completedBottomToTopDiagnolChecked;
    @property NSMutableArray *bottomToTopDiagnolValues;
    @property BOOL completedTopToBottomDiagnolChecked;
    @property NSMutableArray *topToBottomDiagnolValues;
    @property BOOL completedCornersChecked;
    @property NSMutableArray *cornerValues;
    @property BOOL isBuildingGrid;
    @property int dimensions;
    @property (nonatomic) NSMutableArray *gameArray;
    @property (nonatomic) UIView *gameView;
    @property (nonatomic) int gridLength;
    @property (nonatomic) UIButton* makeNewGameButton;
    @property (nonatomic) int playCount;
    @property (nonatomic) int keyboardHeight;
    @property (nonatomic) UIColor *metaGameDrawingColor;
    @property (nonatomic) UIColor *gridColor;
    @property (nonatomic) UIColor *XColor;
    @property (nonatomic) UIColor *OColor;
    @property (nonatomic) UIColor *backgroundColor;

    @property (weak, nonatomic) IBOutlet UIImageView *currentPlayerImage;
    @property (weak, nonatomic) IBOutlet UILabel *currentPlayerLabel;
    @property (weak, nonatomic) IBOutlet UITextField *dimensionTextField;
    @property (weak, nonatomic) IBOutlet UIStackView *dimensionStackView;

@end

@implementation TicTacToeViewController

//MARK: View Controller Class

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dimensions = kDimensionDefault;
    self.dimensionTextField.text = [NSString stringWithFormat: @"%d" , self.dimensions];
    
    self.metaGameDrawingColor = [UIColor blackColor];
    self.XColor = [UIColor redColor];
    self.OColor = [UIColor blueColor];
    self.gridColor = [UIColor blackColor];
    self.backgroundColor = [UIColor whiteColor];
    
    self.view.backgroundColor = self.backgroundColor;
    self.dimensionTextField.backgroundColor = self.backgroundColor;
    
    self.isBuildingGrid = NO;
    
    self.gridLength = self.view.frame.size.width - kGridInset - kGridInset; //both left and right insets
    [self addObserver:self forKeyPath:@"playCount" options:NSKeyValueObservingOptionOld context:nil];
    
    self.gameView = [[UIView alloc] initWithFrame:self.view.frame];
    self.gameView.opaque = NO;
    
    UIPinchGestureRecognizer *twoFingerPinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingerPinch:)];
    
    [[self gameView] addGestureRecognizer:twoFingerPinchRecognizer];
    
    [self.view insertSubview:self.gameView belowSubview: self.dimensionStackView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignFirstResponderOfDimensionTextField)];
    
    [self.view addGestureRecognizer:tap];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [self makeTicTacToeGame];
    
    [self newGameButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString: @"playCount"]) {
        [self updatePlayerImage];
    }
}

//MARK: Custom Dimension and Associated Text Field Handlers

- (int) dimensionTextAsInt {
    int dimensionTextFieldStringToInt = [self.dimensionTextField.text intValue];
    if (dimensionTextFieldStringToInt > kMinimumDimension && dimensionTextFieldStringToInt <= kMaximumDimension) {
        return dimensionTextFieldStringToInt;
    } else {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle: NSNumberFormatterSpellOutStyle];
        NSString *maximumDimensionAsLetters = [formatter stringFromNumber:[NSNumber numberWithInt: kMaximumDimension]];
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:kDimensionTitle
                                                                       message:[NSString stringWithFormat:
                                                                                kDimensionMessageString, maximumDimensionAsLetters]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:kOK style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        
        self.dimensionTextField.text = [NSString stringWithFormat: kDigit, kDimensionDefault];
        
        return kFour;
    }
}

- (IBAction)dimensionEditingDidEnd:(UITextField *)sender {
    [self dimensionTextAsInt];
}
- (IBAction)dimensionTextFieldDidBeginEditing:(UITextField *)sender {
}

- (void) resignFirstResponderOfDimensionTextField
{
    [self.dimensionTextField resignFirstResponder];
    
    [self dimensionTextAsInt];
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.makeNewGameButton.hidden = YES;
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.dimensionTextField resignFirstResponder];
    return NO;
}


-(void)textFieldDidEndEditing:(UITextField *)textField
{
    self.makeNewGameButton.hidden = NO;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:.3];
    [UIView setAnimationBeginsFromCurrentState:TRUE];
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + self.keyboardHeight, self.view.frame.size.width, self.view.frame.size.height);
    
    self.gameView.center = self.view.center;
    
    [UIView commitAnimations];
    
}

- (void)keyboardDidShow:(NSNotification*)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    self.keyboardHeight = [keyboardFrameBegin CGRectValue].size.height;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kKeyboardTransitionAnimationDuration];
    [UIView setAnimationBeginsFromCurrentState:TRUE];
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - self.keyboardHeight, self.view.frame.size.width, self.view.frame.size.height);
    
    [UIView commitAnimations];
}

//MARK: Drawings

- (void) drawOUsingFrame:(CGRect)frame {
    double radius = [self circleRadius];
    double diameter = [self circleDiameter:radius];
    double invertedDiameter = diameter * kNegativeOne;
    double strokeWidth = kXAndOLineWidth / log(self.dimensions);
    CGColorRef color = [UIColor blueColor].CGColor;
    
    CGFloat startAngle = kZero;
    CGFloat endAngle = kOne;
    
    CAShapeLayer *circle = [CAShapeLayer layer];
    if (rand() % 2 == 0) {
        circle.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(kZero, kZero, diameter, diameter) cornerRadius:radius].CGPath;
    } else {
        circle.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(diameter, diameter, invertedDiameter, invertedDiameter) cornerRadius:radius].CGPath;
    }
    
    circle.position = CGPointMake(CGRectGetMidX(frame)-radius, CGRectGetMidY(frame)-radius);
    
    circle.fillColor = [UIColor clearColor].CGColor;
    circle.strokeColor = color;
    circle.lineWidth = strokeWidth;
    
    [self.gameView.layer addSublayer:circle];
    circle.strokeEnd = endAngle;
    
    CABasicAnimation *drawAnimation = [CABasicAnimation animationWithKeyPath:kStrokeEnd];
    drawAnimation.duration  = kXAndOAnimationDuration;
    drawAnimation.fromValue = [NSNumber numberWithFloat:startAngle];
    drawAnimation.toValue   = [NSNumber numberWithFloat:endAngle];
    
    drawAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [circle addAnimation:drawAnimation forKey:kdrawOAnimation];
}

- (double) circleRadius {
    return self.gridLength/((double) self.dimensions)/4;
}

- (double) circleDiameter:(double)radius {
    return kTwo * radius;
}

- (void) drawXUsingFrame:(CGRect)frame {
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kZero * NSEC_PER_SEC));
    int rand1 = rand();
    if (rand1 % 2 == 0) {
        startTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSecondHalfOfXWaitSeconds * NSEC_PER_SEC));
    }
    
    dispatch_after(startTime, dispatch_get_main_queue(), ^(void){
    
        UIBezierPath *path1 = [UIBezierPath bezierPath];
        if (rand() % 2 == 0) {
            [path1 moveToPoint:CGPointMake(frame.origin.x + frame.size.width/4.5, frame.origin.y + frame.size.height/4.5)];
            [path1 addLineToPoint:CGPointMake(frame.origin.x + frame.size.width*3.5/4.5, frame.origin.y + frame.size.height*3.5/4.5)];
        } else {
            [path1 moveToPoint:CGPointMake(frame.origin.x + frame.size.width*3.5/4.5, frame.origin.y + frame.size.height*3.5/4.5)];
            [path1 addLineToPoint:CGPointMake(frame.origin.x + frame.size.width/4.5, frame.origin.y + frame.size.height/4.5)];
        }
        CAShapeLayer *path1Layer = [CAShapeLayer layer];
        path1Layer.frame = self.gameView.bounds;
        path1Layer.strokeColor = [[UIColor redColor] CGColor];
        path1Layer.fillColor = nil;
        path1Layer.lineWidth = kXAndOLineWidth / log(self.dimensions);
        path1Layer.lineJoin = kCALineJoinBevel;
    
        [self.gameView.layer addSublayer:path1Layer];
    
        CABasicAnimation *path1Animation = [CABasicAnimation animationWithKeyPath:kStrokeEnd];
        path1Animation.duration = kXAndOAnimationDuration/kTwo; //half of X is drawn in half the time of a circle
        path1Animation.fromValue = [NSNumber numberWithFloat:kZero];
        path1Animation.toValue = [NSNumber numberWithFloat:kOne];
        [path1Layer addAnimation:path1Animation forKey:kDrawLineAnimation];
        path1Layer.path = path1.CGPath;
    });
    
    if (rand1 % kTwo == kZero) {
        startTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kZero * NSEC_PER_SEC));
    } else {
        startTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSecondHalfOfXWaitSeconds * NSEC_PER_SEC));
    }
    
    dispatch_after(startTime, dispatch_get_main_queue(), ^(void){
        UIBezierPath *path2 = [UIBezierPath bezierPath];
        if (rand() % kTwo == kZero) {
            [path2 moveToPoint:CGPointMake(frame.origin.x + frame.size.width*3.5/4.5, frame.origin.y + frame.size.height/4.5)];
            [path2 addLineToPoint:CGPointMake(frame.origin.x + frame.size.width/4.5, frame.origin.y + frame.size.height*3.5/4.5)];
        } else {
            [path2 moveToPoint:CGPointMake(frame.origin.x + frame.size.width/4.5, frame.origin.y + frame.size.height*3.5/4.5)];
            [path2 addLineToPoint:CGPointMake(frame.origin.x + frame.size.width*3.5/4.5, frame.origin.y + frame.size.height/4.5)];
        }
        
        CAShapeLayer *path2Layer = [CAShapeLayer layer];
        path2Layer.frame = self.gameView.bounds;
        
        path2Layer.strokeColor = [[UIColor redColor] CGColor];
        path2Layer.fillColor = nil;
        path2Layer.lineWidth = kXAndOLineWidth / log(self.dimensions);
        path2Layer.lineJoin = kCALineJoinBevel;
        
        [self.gameView.layer addSublayer:path2Layer];
        
        CABasicAnimation *path2Animation = [CABasicAnimation animationWithKeyPath:kStrokeEnd];
        path2Animation.duration = kXAndOAnimationDuration;
        path2Animation.fromValue = [NSNumber numberWithFloat:kZero];
        path2Animation.toValue = [NSNumber numberWithFloat:kOne];
        [path2Layer addAnimation:path2Animation forKey:kDrawLineAnimation];
        path2Layer.path = path2.CGPath;
    });
}

- (void) drawVerticalGridLine:(int)l {
    UIBezierPath *path = [UIBezierPath bezierPath];
    int xCoordinate = (self.gridLength) * l / ((float) self.dimensions) + kGridInset;
    if (rand() % kTwo == kZero) {
        [path moveToPoint:CGPointMake(xCoordinate, self.gameView.center.y - self.gridLength/2)];
        [path addLineToPoint:CGPointMake(xCoordinate, self.gameView.center.y + self.gridLength/2)];
    } else {
        [path moveToPoint:CGPointMake(xCoordinate, self.gameView.center.y + self.gridLength/2)];
        [path addLineToPoint:CGPointMake(xCoordinate, self.gameView.center.y - self.gridLength/2)];
    }
    CAShapeLayer *pathLayer = [CAShapeLayer layer];
    pathLayer.frame = self.gameView.bounds;
    pathLayer.path = path.CGPath;
    pathLayer.strokeColor = [self.gridColor CGColor];
    pathLayer.fillColor = nil;
    pathLayer.lineWidth = kGridLineWidth / log(self.dimensions);
    pathLayer.lineJoin = kCALineJoinBevel;
    
    [self.gameView.layer addSublayer:pathLayer];
    
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:kStrokeEnd];
    pathAnimation.duration = kGridLineAnimationDuration;
    pathAnimation.fromValue = [NSNumber numberWithFloat:kZero];
    pathAnimation.toValue = [NSNumber numberWithFloat:kOne];
    [pathLayer addAnimation:pathAnimation forKey:kDrawLineAnimation];
}

- (void) drawHorizontalGridLine:(int)l {
    UIBezierPath *path = [UIBezierPath bezierPath];
    int yCoordinate = (self.gameView.center.y - self.gridLength/kTwo) + (self.gridLength * l / ((float) self.dimensions));
    if (rand() % kTwo == kZero) {
        [path moveToPoint:CGPointMake(kGridInset, yCoordinate)];
        [path addLineToPoint:CGPointMake(kGridInset + self.gridLength, yCoordinate)];
    } else {
        [path moveToPoint:CGPointMake(kGridInset + self.gridLength, yCoordinate)];
        [path addLineToPoint:CGPointMake(kGridInset, yCoordinate)];
    }
    
    CAShapeLayer *pathLayer = [CAShapeLayer layer];
    pathLayer.frame = self.gameView.bounds;
    pathLayer.path = path.CGPath;
    pathLayer.strokeColor = [self.gridColor CGColor];
    pathLayer.fillColor = nil;
    pathLayer.lineWidth = kGridLineWidth / log(self.dimensions);
    pathLayer.lineJoin = kCALineJoinBevel;
    
    [self.gameView.layer addSublayer:pathLayer];
    
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:kStrokeEnd];
    pathAnimation.duration = kGridLineAnimationDuration;
    pathAnimation.fromValue = [NSNumber numberWithFloat:kZero];
    pathAnimation.toValue = [NSNumber numberWithFloat:kOne];
    [pathLayer addAnimation:pathAnimation forKey:kDrawLineAnimation];
}

//MARK: Player Makes a Move
- (void) playMade:(TicTacToeButton *) sender {
    if (self.dimensionTextField.isFirstResponder) {
        [self resignFirstResponderOfDimensionTextField];
    }
    
    if (self.playCount % kTwo == kZero) {
        [self drawOUsingFrame:sender.frame];
        sender.value = [NSNumber numberWithInteger:O];
    } else {
        [self drawXUsingFrame:sender.frame];
        sender.value = [NSNumber numberWithInteger:X];
    }
    
    if (sender.isBottomToTopDiagnol) {
        [self.bottomToTopDiagnolValues addObject:sender.value];
    }
    
    if (sender.isCorner) {
        [self.cornerValues addObject:sender.value];
    }
    
    if (sender.isTopToBottomDiagnol) {
        [self.topToBottomDiagnolValues addObject:sender.value];
    }
    
    NSNumber *x = sender.coordinates[kZero];
    NSMutableArray *innerArray = [self.gameArray objectAtIndex:[x integerValue]];
    NSNumber *y = sender.coordinates[kOne];
    
    NSNumber *newValue = sender.value;
    [innerArray replaceObjectAtIndex:[y integerValue] withObject:newValue];
    
    self.playCount++;
    int xInt = [x intValue];
    int yInt = [y intValue];
    
    [self check:newValue WinOf:xInt And:yInt];
    
    sender.enabled = NO;
}

- (void) updatePlayerImage {
    CATransition *transition = [CATransition animation];
    transition.duration = kImageTransitionDuration;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    transition.delegate = self;
    [self.view.layer addAnimation:transition forKey:nil];
    
    if (self.playCount % kTwo == kZero) {
        self.currentPlayerImage.image = [UIImage imageNamed:kOImageName];
    } else {
        self.currentPlayerImage.image = [UIImage imageNamed:kXImageName];
    }
}


//MARK: New Game Methods

- (void) makeTicTacToeGame {
    self.dimensions = [self dimensionTextAsInt];
    
    self.gameView.center = self.view.center;
    self.gameView.transform = CGAffineTransformIdentity;
    
    [self.currentPlayerLabel setTextColor:self.metaGameDrawingColor];
    
    self.bottomToTopDiagnolValues = [[NSMutableArray alloc] initWithCapacity:self.dimensions];
    self.completedBottomToTopDiagnolChecked = NO;
    self.topToBottomDiagnolValues = [[NSMutableArray alloc] initWithCapacity:self.dimensions];
    self.completedTopToBottomDiagnolChecked = NO;
    self.cornerValues = [[NSMutableArray alloc] initWithCapacity:kFour];
    self.completedCornersChecked = NO;
    self.gameArray = [[NSMutableArray alloc] initWithCapacity:self.dimensions];
    
    self.playCount = arc4random() % kTwo;
    
    self.currentPlayerLabel.text = kCurrentPlayerLabelTitle;
    [self.currentPlayerLabel setTextColor:self.metaGameDrawingColor];
    
    self.isBuildingGrid = YES;
    
    [self drawGrid];
    
    [self addButtons];
}

- (void) drawGrid {
    for (int lineNumber = kOne; lineNumber < self.dimensions; lineNumber++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (double)arc4random() / ARC4RANDOM_MAX
                                                         * 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self drawVerticalGridLine:lineNumber];
        });
        __weak typeof (self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (double)arc4random() / ARC4RANDOM_MAX
                                     * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self drawHorizontalGridLine:lineNumber];
            if (lineNumber == weakSelf.dimensions - 1) {
                weakSelf.isBuildingGrid = NO;
            }
        });
    }
}

- (void) addButtons {
    for (int x = kZero; x < self.dimensions; x++) {
        NSMutableArray *xArray = [[NSMutableArray alloc] initWithCapacity:self.dimensions];
        for (int y = kZero; y < self.dimensions; y++) {
            [xArray addObject:[NSNumber numberWithInt:kZero]];
            [self makeTicTacToeButtonAt:x And:y];
        }
        [self.gameArray addObject:xArray];
    }
}

- (void) makeTicTacToeButtonAt:(int)x And:(int) y {
    TicTacToeButton *button = [TicTacToeButton buttonWithType:UIButtonTypeCustom];
    button.coordinates = [NSArray arrayWithObjects:[NSNumber numberWithInt:x], [NSNumber numberWithInt:y],nil];
    button.value = [NSNumber numberWithInt:0];
    
    if ((x == 0 && y == 0) || (x == 0 && y == self.dimensions - 1)
        || (x == self.dimensions - 1 && y == 0)
        || (x == self.dimensions - 1 && y == self.dimensions - 1)) {
        button.isCorner = YES;
    } else {
        button.isCorner = NO;
    }
    
    button.isTopToBottomDiagnol = (y == x);
    button.isBottomToTopDiagnol = NO;
    for (int i = kZero; i < self.dimensions; i++) {
        if (x == i && y == self.dimensions - 1 - i) {
            button.isBottomToTopDiagnol = YES;
        }
    }
    
    [button addTarget:self
               action:@selector(playMade:)
     forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(x/((float) self.dimensions) * self.gridLength + kGridInset + kButtonInset,
                              y/((float) self.dimensions) * self.gridLength + (self.gameView.center.y - self.gridLength/2) + kButtonInset,
                              self.gridLength/((float) self.dimensions) - kButtonInset * kTwo,
                              self.gridLength/((float) self.dimensions) - kButtonInset * kTwo);
    button.restorationIdentifier = kGameButtonID;
    [self.gameView addSubview:button];
}


- (void) newGameButton {
    self.makeNewGameButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.makeNewGameButton addTarget:self
               action:@selector(newGame:)
     forControlEvents:UIControlEventTouchUpInside];
    self.makeNewGameButton.frame = CGRectMake(kGridInset, [UIScreen mainScreen].bounds.size.height - 125, [UIScreen mainScreen].bounds.size.width - kGridInset * kTwo, 30);
    self.makeNewGameButton.layer.cornerRadius = 10;
    self.makeNewGameButton.hidden = NO;
    [self.makeNewGameButton.layer setBorderWidth:kButtonBorderWidth];
    [self.makeNewGameButton.layer setBorderColor:[self.metaGameDrawingColor CGColor]];
    [self.makeNewGameButton setTitleColor:self.metaGameDrawingColor forState:UIControlStateNormal];
    
    [self.makeNewGameButton setTitle:kNewGameButtonTitle forState:UIControlStateNormal];
    [self.view addSubview:self.makeNewGameButton];
}

- (void) newGame:(UIButton *)sender {
    self.gameView.layer.sublayers = nil;
    
    [self makeTicTacToeGame];
}

//MARK: Win Check Method

- (BOOL) check:(NSNumber *)value WinOf:(int)x And:(int)y {
    //Check Bottom-to-Top Diagnol
    if ((!self.completedBottomToTopDiagnolChecked) && (self.bottomToTopDiagnolValues.count == self.dimensions)) {
        if (![self.bottomToTopDiagnolValues containsObject: [NSNumber numberWithInt:empty]]) {
            if (![self.bottomToTopDiagnolValues containsObject: [NSNumber numberWithInt:O]]) {
                [self won:[NSNumber numberWithInt: X] by:kRow];
            }
            if (![self.bottomToTopDiagnolValues containsObject: [NSNumber numberWithInt:X]]) {
                [self won:[NSNumber numberWithInt: O] by:kRow];
            }
        }
        self.completedBottomToTopDiagnolChecked = YES;
    }
    
    //Check the four corners
    if ((!self.completedCornersChecked) && (self.cornerValues.count == kFour)) {
        if ((self.cornerValues[kZero] == self.cornerValues[kOne]) && (self.cornerValues[kOne] == self.cornerValues[kTwo]) && (self.cornerValues[kTwo] == self.cornerValues[kThree])) {
            [self won:value by: kFourCorners];
        }
        self.completedCornersChecked = YES;
    }
    
    //Check Top-to-Bottom Diagnol
    if ((!self.completedTopToBottomDiagnolChecked) && (self.topToBottomDiagnolValues.count == self.dimensions)) {
        if (![self.topToBottomDiagnolValues containsObject: [NSNumber numberWithInt:empty]]) {
            if (![self.topToBottomDiagnolValues containsObject: [NSNumber numberWithInt:O]]) {
                [self won:[NSNumber numberWithInt: X] by:kRow];
            }
            if (![self.topToBottomDiagnolValues containsObject: [NSNumber numberWithInt:X]]) {
                [self won:[NSNumber numberWithInt: O] by:kRow];
            }
        }
        self.completedTopToBottomDiagnolChecked = YES;
    }
    
    //Check column
    NSArray *columnAtX = [self getColumnArrayOfX:x];
    if (![columnAtX containsObject: [NSNumber numberWithInt:empty]]) {
        if (![columnAtX containsObject: [NSNumber numberWithInt:O]]) {
            [self won:[NSNumber numberWithInt: X] by:kRow];
        }
        if (![columnAtX containsObject: [NSNumber numberWithInt:X]]) {
            [self won:[NSNumber numberWithInt: O] by:kRow];
        }
    }
    
    //Check row
    NSArray *rowAtY = [self getRowArrayOfY:y];
    if (![rowAtY containsObject: [NSNumber numberWithInt:empty]]) {
        if (![rowAtY containsObject: [NSNumber numberWithInt:O]]) {
            [self won:[NSNumber numberWithInt: X] by:kRow];
        }
        if (![rowAtY containsObject: [NSNumber numberWithInt:X]]) {
            [self won:[NSNumber numberWithInt: O] by:kRow];
        }
    }
    
    //Check for box that is perfect square root of dimension by perfect square root
    int perfectSquareRoot = [self checkForPerfectSquare:self.dimensions];

    if (perfectSquareRoot) { //only check if a square root exists as an integer
        int oppositeValue = O;
        if ([value integerValue] == O) {
            oppositeValue = X;
        }
        for (int i = kZero; i < columnAtX.count - perfectSquareRoot + 1; i++) {
            NSArray *subColumnOfColumnXStartngAtIOfSizeSquareRoot = [columnAtX subarrayWithRange:NSMakeRange(i, perfectSquareRoot)];
            if (![subColumnOfColumnXStartngAtIOfSizeSquareRoot containsObject: [NSNumber numberWithInt:empty]] &&
                ![subColumnOfColumnXStartngAtIOfSizeSquareRoot containsObject: [NSNumber numberWithInt:oppositeValue]]) {
                int j = x - perfectSquareRoot + kOne;
                if (j < 0) {
                    j = 0;
                }
                
                for (; j < self.gameArray.count - perfectSquareRoot + kOne; j++) {
                    int squareColumnConsistencyCounter = kZero;
                    for (int k = i; k < i + perfectSquareRoot; k++) {
                        if (![[[self getRowArrayOfY:k] subarrayWithRange:NSMakeRange(j, perfectSquareRoot)] containsObject: [NSNumber numberWithInt:empty]] && ![[[self getRowArrayOfY:k] subarrayWithRange:NSMakeRange(j, perfectSquareRoot)] containsObject: [NSNumber numberWithInt:oppositeValue]]) {
                            squareColumnConsistencyCounter++;
                            if (squareColumnConsistencyCounter == perfectSquareRoot) {
                                [self won:value by:kSquare];
                            }
                        } else {
                            squareColumnConsistencyCounter = kZero;
                        }
                    }
                }
            }
        }
    }
    return false;
}

//MARK: Win Method Call

- (void) won:(NSNumber *)winner by:(NSString *) winningMethodString {
    self.currentPlayerLabel.text = [kWinAnnouncementBeginning stringByAppendingString:winningMethodString];
    if ([winner integerValue] == O) {
        self.currentPlayerImage.image = [UIImage imageNamed:kOImageName];
    } else {
        self.currentPlayerImage.image = [UIImage imageNamed:kXImageName];
    }
    
    for (UIView * view in self.gameView.subviews) {
        if ([view.restorationIdentifier isEqualToString:kGameButtonID]) {
            view.userInteractionEnabled = NO;
        }
    }
    for (int i = kZero; i < kFour; i += kOne) {
        dispatch_time_t startTime1 = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * NSEC_PER_SEC));
        dispatch_after(startTime1, dispatch_get_main_queue(), ^(void){
            [self.currentPlayerLabel setTextColor:UIColor.redColor];
        });
        dispatch_time_t startTime2 = dispatch_time(DISPATCH_TIME_NOW, (int64_t)((i+1) * NSEC_PER_SEC));
        dispatch_after(startTime2, dispatch_get_main_queue(), ^(void){
            [self.currentPlayerLabel setTextColor:UIColor.blueColor];
        });
    }
}

//MARK: Row and Column Getters

- (NSArray *) getRowArrayOfY:(int) y {
    NSMutableArray *pointYArray = [[NSMutableArray alloc] initWithCapacity:self.dimensions];
    for (NSArray * xArray in self.gameArray) {
        [pointYArray addObject:[xArray objectAtIndex:y]];
    }
    return pointYArray;
}

- (NSArray *) getColumnArrayOfX:(int) x {
    return [self.gameArray objectAtIndex:x];
}


//MARK: Possibility of Perfect Square Check
//Not needed unless square search is implemented from 4 to N

- (int) checkForPerfectSquare:(int) x {
    for(int a = kZero; a <= x; a++)
    {
        if (x == a * a)
        {
            return a;
        }
    }
    return kZero;
}

//MARK: Pinch Zoom for Game View

- (void)twoFingerPinch:(UIPinchGestureRecognizer *)recognizer
{
    CGAffineTransform transform = CGAffineTransformMakeScale(recognizer.scale, recognizer.scale);
    // you can implement any int/float value in context of what scale you want to zoom in or out
    self.gameView.transform = transform;
}

//MARK: Move Game View

float startX = kZero;
float startY = kZero;
-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    
    if( [touch view] == self.gameView)
    {
        CGPoint location = [touch locationInView:self.view];
        startX = location.x - self.gameView.center.x;
        startY = location.y - self.gameView.center.y;
    }
}
- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [[event allTouches] anyObject];
    if( [touch view] == self.gameView && !self.isBuildingGrid)
    {
        CGPoint location = [touch locationInView:self.view];
        location.x =location.x - startX;
        location.y = location.y - startY;
        self.gameView.center = location;
    }
}

@end
