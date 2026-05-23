#import <substrate.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "../Native/PredictionEngine.h"

static PredictionEngine* s_engine = nullptr;
static UIView* s_overlayView = nil;

// Hook into UI rendering to draw prediction lines
static void (*orig_UIView_drawRect)(UIView* self, SEL sel, CGRect rect);
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
        for (size_t j = 1; j < ball.trail.size(); j++) {
            CGContextAddLineToPoint(ctx, ball.trail[j].x, ball.trail[j].y);
        }
    }
    CGContextStrokePath(ctx);
}

// Hook GameManager to read game state
static void (*orig_GameManager_update)(void* self);
static void hook_GameManager_update(void* self) {
    orig_GameManager_update(self);

    if (!s_engine) {
        s_engine = new PredictionEngine();
    }

    // Read cue data from game (using Objective-C runtime)
    // In real impl, use MSHookIvar or memory reads
    double angle = 0.0, power = 0.0;
    Vector2D spin;

    @try {
        Ivar cueIvar = object_getInstanceVariable(self, "mVisualCue", NULL);
        if (cueIvar) {
            void* cue = (__bridge void*)object_getIvar((__bridge id)self, cueIvar);
            if (cue) {
                // Read angle/power/spin from VisualCue object
                // angle = *(double*)(cue + 0x...);
                // power = *(double*)(cue + 0x...);
            }
        }
    } @catch (NSException* e) {
        // Not in a match, skip
        return;
    }

    s_engine->determineShotResult(angle, power, spin);
}

static void (*orig_CCDirector_drawScene)(void* self);
static void hook_CCDirector_drawScene(void* self) {
    orig_CCDirector_drawScene(self);

    if (s_engine && s_engine->guiData.ballsCount > 0) {
        // Trigger overlay redraw
        [s_overlayView setNeedsDisplay];
    }
}

__attribute__((constructor))
static void init() {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    // Find the main window to add overlay
    UIWindow* keyWindow = [UIApplication sharedApplication].keyWindow;
    if (keyWindow) {
        s_overlayView = [[UIView alloc] initWithFrame:keyWindow.bounds];
        s_overlayView.backgroundColor = [UIColor clearColor];
        s_overlayView.userInteractionEnabled = NO;
        [keyWindow addSubview:s_overlayView];

        // Hook drawRect on the overlay
        MSHookMessageEx(
            [UIView class],
            @selector(drawRect:),
            (IMP)&hook_UIView_drawRect,
            (IMP*)&orig_UIView_drawRect
        );
    }

    [pool drain];
}
