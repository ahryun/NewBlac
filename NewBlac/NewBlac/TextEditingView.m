//
//  TextEditingView.m
//  NewBlac
//
//  Created by Ahryun Moon on 3/27/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "TextEditingView.h"
#import "Strings.h"

@interface TextEditingView() <UITextViewDelegate>

@property (nonatomic, weak) UITextView *titleField;

@end

@implementation TextEditingView

@synthesize delegate;

- (void)setVideoImage:(UIImage *)videoImage
{
    _videoImage = videoImage;
    [self initializeTextEditingView];
}

- (void)initializeTextEditingView
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, LABEL_HEIGHT)];
    label.text = NSLocalizedString(@"Add Title", @"Ask the user to set a title for the video");
    label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:24];
    label.bounds = CGRectMake(0, S_OFFSET_TOP, self.frame.size.width, LABEL_HEIGHT - S_OFFSET_TOP);
    label.textColor = PINK_COLOR;
    label.textAlignment = NSTextAlignmentCenter;
    CALayer* layer = [label layer];
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.borderColor = [UIColor lightGrayColor].CGColor;
    bottomBorder.borderWidth = 1;
    bottomBorder.frame = CGRectMake(-1, LABEL_HEIGHT-1, layer.frame.size.width, 1);
    [layer addSublayer:bottomBorder];
    [self addSubview:label];
    
    UIImageView *videoImageView = [[UIImageView alloc] initWithImage:self.videoImage];
    CGFloat height = IMAGE_WIDTH / self.videoImage.size.width * self.videoImage.size.height;
    [videoImageView setFrame:CGRectMake(PADDING, LABEL_HEIGHT + PADDING, IMAGE_WIDTH, height)];
    [self addSubview:videoImageView];
    
    CGFloat textFieldWidth = CGRectGetWidth(self.bounds) - IMAGE_WIDTH - (2 * PADDING);
    UITextView *titleField = [[UITextView alloc] initWithFrame:CGRectMake(IMAGE_WIDTH + (2 * PADDING), LABEL_HEIGHT + PADDING, textFieldWidth, TEXTFIELD_HEIGHT)];
    titleField.text = self.existingTitle;
    titleField.keyboardAppearance = UIKeyboardAppearanceDark;
    titleField.keyboardType = UIKeyboardTypeASCIICapable;
    titleField.returnKeyType = UIReturnKeyDone;
    titleField.textColor = [UIColor lightGrayColor];
    titleField.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
    titleField.delegate = self;
    [titleField becomeFirstResponder];
    [self addSubview:titleField];
    self.titleField = titleField;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSUInteger newLength = [textView.text length] + [text length] - range.length;
    if ([text isEqual:@"\n"]) {
        [textView resignFirstResponder];
        [self.delegate saveTitle:self.titleField.text];
        [self.delegate dismissTextEditingViewDelegate:self];
        return NO;
    }
    return (newLength > MAX_TEXT_LENGTH) ? NO : YES;
}

@end
