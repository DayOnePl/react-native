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
#import <React/RCTShadowView+Layout.h>
#import <React/RCTShadowView.h>

#import "RCTConvert+Text.h"
#import "RCTShadowTextField.h"
#import "RCTTextField.h"
#import "RCTUITextField.h"

@implementation RCTTextFieldManager

RCT_EXPORT_MODULE()

- (RCTShadowView *)shadowView
{
  return [RCTShadowTextField new];
}

- (UIView *)view
{
  return [[RCTTextField alloc] initWithBridge:self.bridge];
}

#pragma mark - Unified <TextInput> properties

RCT_REMAP_VIEW_PROPERTY(allowFontScaling, fontAttributes.allowFontScaling, BOOL)
RCT_REMAP_VIEW_PROPERTY(autoCapitalize, backedTextInputView.autocapitalizationType, UITextAutocapitalizationType)
RCT_REMAP_VIEW_PROPERTY(autoCorrect, backedTextInputView.autocorrectionType, UITextAutocorrectionType)
RCT_REMAP_VIEW_PROPERTY(color, backedTextInputView.textColor, UIColor)
RCT_REMAP_VIEW_PROPERTY(editable, backedTextInputView.editable, BOOL)
RCT_REMAP_VIEW_PROPERTY(enablesReturnKeyAutomatically, backedTextInputView.enablesReturnKeyAutomatically, BOOL)
RCT_REMAP_VIEW_PROPERTY(fontSize, fontAttributes.fontSize, NSNumber)
RCT_REMAP_VIEW_PROPERTY(fontWeight, fontAttributes.fontWeight, NSString)
RCT_REMAP_VIEW_PROPERTY(fontStyle, fontAttributes.fontStyle, NSString)
RCT_REMAP_VIEW_PROPERTY(fontFamily, fontAttributes.fontFamily, NSString)
RCT_REMAP_VIEW_PROPERTY(keyboardAppearance, backedTextInputView.keyboardAppearance, UIKeyboardAppearance)
RCT_REMAP_VIEW_PROPERTY(keyboardType, backedTextInputView.keyboardType, UIKeyboardType)
RCT_REMAP_VIEW_PROPERTY(placeholder, backedTextInputView.placeholder, NSString)
RCT_REMAP_VIEW_PROPERTY(placeholderTextColor, backedTextInputView.placeholderColor, UIColor)
RCT_REMAP_VIEW_PROPERTY(returnKeyType, backedTextInputView.returnKeyType, UIReturnKeyType)
RCT_REMAP_VIEW_PROPERTY(secureTextEntry, backedTextInputView.secureTextEntry, BOOL)
RCT_REMAP_VIEW_PROPERTY(selectionColor, backedTextInputView.tintColor, UIColor)
RCT_REMAP_VIEW_PROPERTY(spellCheck, backedTextInputView.spellCheckingType, UITextSpellCheckingType)
RCT_REMAP_VIEW_PROPERTY(textAlign, backedTextInputView.textAlignment, NSTextAlignment)
RCT_EXPORT_VIEW_PROPERTY(blurOnSubmit, BOOL)
RCT_EXPORT_VIEW_PROPERTY(clearTextOnFocus, BOOL)
RCT_EXPORT_VIEW_PROPERTY(maxLength, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(selectTextOnFocus, BOOL)
RCT_EXPORT_VIEW_PROPERTY(selection, RCTTextSelection)
RCT_EXPORT_VIEW_PROPERTY(text, NSString)

#pragma mark - Singleline <TextInput> (aka TextField) specific properties

RCT_REMAP_VIEW_PROPERTY(caretHidden, backedTextInputView.caretHidden, BOOL)
RCT_REMAP_VIEW_PROPERTY(clearButtonMode, backedTextInputView.clearButtonMode, UITextFieldViewMode)
RCT_EXPORT_VIEW_PROPERTY(onSelectionChange, RCTDirectEventBlock)

RCT_EXPORT_VIEW_PROPERTY(mostRecentEventCount, NSInteger)

- (RCTViewManagerUIBlock)uiBlockToAmendWithShadowView:(RCTShadowView *)shadowView
{
  NSNumber *reactTag = shadowView.reactTag;
  UIEdgeInsets borderAsInsets = shadowView.borderAsInsets;
  UIEdgeInsets paddingAsInsets = shadowView.paddingAsInsets;
  return ^(RCTUIManager *uiManager, NSDictionary<NSNumber *, RCTTextInput *> *viewRegistry) {
    RCTTextInput *view = viewRegistry[reactTag];
    view.reactBorderInsets = borderAsInsets;
    view.reactPaddingInsets = paddingAsInsets;
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
