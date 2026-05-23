#import <substrate.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "../Native/PredictionEngine.h"

static PredictionEngine* s_engine = nullptr;
static UIView* s_overlayView = nil;

static void (*orig_UIView_drawRect)(UIView*, SEL, CGRect);
static void hook_UIView_drawRect(UIView* self, SEL sel, CGRect rect) {
    orig_UIView_drawRect(self, sel, rect);
    if (!s_engine) return;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;
    CGContextSetStrokeColorWithColor(ctx, [UIColor redColor].CGColor);
    CGContextSetLineWidth(ctx, 2.0);
    for (int i = 0; i < s_engine->guiData.ballsCount; i++) {
        auto& ball = s_engine->guiData.balls[i];
        if (ball.trail.size() < 2) continue;
        CGContextMoveToPoint(ctx, ball.trail[0].x, ball.trail[0].y);
        for (size_t j = 1; j < ball.trail.size(); j++)
            CGContextAddLineToPoint(ctx, ball.trail[j].x, ball.trail[j].y);
    }
    CGContextStrokePath(ctx);
}

__attribute__((constructor))
static void init() {
    @autoreleasepool {
        UIWindow* keyWindow = [UIApplication sharedApplication].keyWindow;
        if (keyWindow) {
            s_overlayView = [[UIView alloc] initWithFrame:keyWindow.bounds];
            s_overlayView.backgroundColor = [UIColor clearColor];
            s_overlayView.userInteractionEnabled = NO;
            [keyWindow addSubview:s_overlayView];
            MSHookMessageEx([UIView class], @selector(drawRect:),
                (IMP)&hook_UIView_drawRect, (IMP*)&orig_UIView_drawRect);
        }
    }
}
