/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTTextFieldManager.h"

#import <React/RCTBridge.h>
#import <React/RCTFont.h>
#import <React/RCTShadowView.h>

#import "RCTTextField.h"
#import "RCTConvert+Text.h"

@interface RCTTextFieldManager() <UITextFieldDelegate>

@end

@implementation RCTTextFieldManager

RCT_EXPORT_MODULE()

- (UIView *)view
{
  RCTTextField *textField = [[RCTTextField alloc] initWithEventDispatcher:self.bridge.eventDispatcher];
  textField.delegate = self;
  return textField;
}

- (BOOL)textField:(RCTTextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
  // Only allow single keypresses for onKeyPress, pasted text will not be sent.
  if (textField.textWasPasted) {
    textField.textWasPasted = NO;
  } else {
    [textField sendKeyValueForString:string];
  }

  if (textField.maxLength == nil || [string isEqualToString:@"\n"]) {  // Make sure forms can be submitted via return
    return YES;
  }
  NSUInteger allowedLength = textField.maxLength.integerValue - MIN(textField.maxLength.integerValue, textField.text.length) + range.length;
  if (string.length > allowedLength) {
    if (string.length > 1) {
      // Truncate the input string so the result is exactly maxLength
      NSString *limitedString = [string substringToIndex:allowedLength];
      NSMutableString *newString = textField.text.mutableCopy;
      [newString replaceCharactersInRange:range withString:limitedString];
      textField.text = newString;
      // Collapse selection at end of insert to match normal paste behavior
      UITextPosition *insertEnd = [textField positionFromPosition:textField.beginningOfDocument
                                                          offset:(range.location + allowedLength)];
      textField.selectedTextRange = [textField textRangeFromPosition:insertEnd toPosition:insertEnd];
      [textField textFieldDidChange];
    }
    return NO;
  } else {
    return YES;
  }
}

// This method allows us to detect a `Backspace` keyPress
// even when there is no more text in the TextField
- (BOOL)keyboardInputShouldDelete:(RCTTextField *)textField
{
  [self textField:textField shouldChangeCharactersInRange:NSMakeRange(0, 0) replacementString:@""];
  return YES;
}

- (BOOL)textFieldShouldEndEditing:(RCTTextField *)textField
{
  return [textField textFieldShouldEndEditing:textField];
}

RCT_EXPORT_VIEW_PROPERTY(caretHidden, BOOL)
RCT_REMAP_VIEW_PROPERTY(autoCorrect, autocorrectionType, UITextAutocorrectionType)
RCT_REMAP_VIEW_PROPERTY(spellCheck, spellCheckingType, UITextSpellCheckingType)
RCT_REMAP_VIEW_PROPERTY(editable, enabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(placeholder, NSString)
RCT_EXPORT_VIEW_PROPERTY(placeholderTextColor, UIColor)
RCT_EXPORT_VIEW_PROPERTY(selection, RCTTextSelection)
RCT_EXPORT_VIEW_PROPERTY(text, NSString)
RCT_EXPORT_VIEW_PROPERTY(maxLength, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(clearButtonMode, UITextFieldViewMode)
RCT_REMAP_VIEW_PROPERTY(clearTextOnFocus, clearsOnBeginEditing, BOOL)
RCT_EXPORT_VIEW_PROPERTY(selectTextOnFocus, BOOL)
RCT_EXPORT_VIEW_PROPERTY(blurOnSubmit, BOOL)
RCT_EXPORT_VIEW_PROPERTY(keyboardType, UIKeyboardType)
RCT_EXPORT_VIEW_PROPERTY(keyboardAppearance, UIKeyboardAppearance)
RCT_EXPORT_VIEW_PROPERTY(onSelectionChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(returnKeyType, UIReturnKeyType)
RCT_EXPORT_VIEW_PROPERTY(enablesReturnKeyAutomatically, BOOL)
RCT_EXPORT_VIEW_PROPERTY(secureTextEntry, BOOL)
RCT_REMAP_VIEW_PROPERTY(password, secureTextEntry, BOOL) // backwards compatibility
RCT_REMAP_VIEW_PROPERTY(color, textColor, UIColor)
RCT_REMAP_VIEW_PROPERTY(autoCapitalize, autocapitalizationType, UITextAutocapitalizationType)
RCT_REMAP_VIEW_PROPERTY(textAlign, textAlignment, NSTextAlignment)
RCT_REMAP_VIEW_PROPERTY(selectionColor, tintColor, UIColor)
RCT_CUSTOM_VIEW_PROPERTY(fontSize, NSNumber, RCTTextField)
{
  view.font = [RCTFont updateFont:view.font withSize:json ?: @(defaultView.font.pointSize)];
}
RCT_CUSTOM_VIEW_PROPERTY(fontWeight, NSString, __unused RCTTextField)
{
  view.font = [RCTFont updateFont:view.font withWeight:json]; // defaults to normal
}
RCT_CUSTOM_VIEW_PROPERTY(fontStyle, NSString, __unused RCTTextField)
{
  view.font = [RCTFont updateFont:view.font withStyle:json]; // defaults to normal
}
RCT_CUSTOM_VIEW_PROPERTY(fontFamily, NSString, RCTTextField)
{
  view.font = [RCTFont updateFont:view.font withFamily:json ?: defaultView.font.familyName];
}
RCT_EXPORT_VIEW_PROPERTY(mostRecentEventCount, NSInteger)

- (RCTViewManagerUIBlock)uiBlockToAmendWithShadowView:(RCTShadowView *)shadowView
{
  NSNumber *reactTag = shadowView.reactTag;
  UIEdgeInsets padding = shadowView.paddingAsInsets;
  return ^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, RCTTextField *> *viewRegistry) {
    viewRegistry[reactTag].contentInset = padding;
  };
}

RCT_CUSTOM_VIEW_PROPERTY(withCompletions, BOOL, RCTTextField)
{
  if (json && [RCTConvert BOOL:json]) {
    UIToolbar* toolbar = [[UIToolbar alloc] init];
    toolbar.tintColor = [UIColor colorWithRed:0.88 green:0.31 blue:0.26 alpha:1];
    [toolbar sizeToFit];
    
    UIScrollView* scrollView = [[UIScrollView alloc]initWithFrame:[toolbar frame]];
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.backgroundColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.95 alpha:1];
    
    
    [scrollView addSubview:toolbar];
    
    view.inputAccessoryView = scrollView;
  } else {
    view.inputAccessoryView = nil;
  }
}

RCT_EXPORT_VIEW_PROPERTY(submitOnComplete, BOOL)

RCT_CUSTOM_VIEW_PROPERTY(completions, NSArray*, RCTTextField)
{
  if (view.inputAccessoryView) {
    //    UIToolbar *toolbar = (UIToolbar *)view.inputAccessoryView;
    UIScrollView *scroll = (UIScrollView *)view.inputAccessoryView;
    UIToolbar *toolbar = [[scroll subviews] firstObject];
    
    if(json) {
      NSArray* completions = [RCTConvert NSArray:json];
      
      NSString *last = [completions lastObject];
      if(completions.count > 0) {
        NSMutableArray *items = [NSMutableArray arrayWithCapacity:([completions count] * 2) -1];
        
        CGFloat separatorHeight = toolbar.frame.size.height * 0.4;
        
        for(NSString* completion in completions) {
          UIBarButtonItem* button = [[UIBarButtonItem alloc]initWithTitle:completion
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:view
                                                                   action:@selector(completionSelected:)];
          
          UIFont * font = [UIFont systemFontOfSize:14];
          NSDictionary * attributes = @{NSFontAttributeName: font};
          [button setTitleTextAttributes:attributes forState:UIControlStateNormal];
          
          [items addObject:button];
          
          if(completion != last) {
            UIView * separator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, separatorHeight)];
            separator.backgroundColor = toolbar.tintColor;
            UIBarButtonItem *separatorButton = [[UIBarButtonItem alloc]initWithCustomView:separator];
            
            [items addObject:separatorButton];
          }
        }
      
        toolbar.items = items;
        
        UIView* lastButton = toolbar.subviews.lastObject;
        float newWidth = lastButton.frame.origin.x +
                         lastButton.frame.size.width +
                         lastButton.layoutMargins.right +
                         toolbar.layoutMargins.left;
        CGRect toolbarFrame = CGRectMake(0, 0, newWidth, toolbar.frame.size.height);
        
        [toolbar setFrame:toolbarFrame];
        scroll.contentSize = toolbarFrame.size;
      } else {
        UIBarButtonItem* button = [[UIBarButtonItem alloc]initWithTitle:@"No matching completions" style:UIBarButtonItemStylePlain target:nil action:nil];
        UIFont * font = [UIFont systemFontOfSize:14];
        NSDictionary * attributes = @{NSFontAttributeName: font};
        [button setTitleTextAttributes:attributes forState:UIControlStateNormal];
       
        toolbar.items = [NSArray arrayWithObject:button];
      }
    }
  }
}

@end
