#import "../../Utils.h"
#import "../../InstagramHeaders.h"

static inline BOOL SCIResponds(id obj, SEL sel) {
    return obj && [obj respondsToSelector:sel];
}

static inline id SCISendId(id obj, SEL sel) {
    if (!SCIResponds(obj, sel)) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(obj, sel);
}

static inline BOOL SCISendBool(id obj, SEL sel) {
    if (!SCIResponds(obj, sel)) return NO;
    return ((BOOL (*)(id, SEL))objc_msgSend)(obj, sel);
}



static NSArray *removeItemsInList(NSArray *list, BOOL isFeed) {
    if (![list isKindOfClass:[NSArray class]]) return list;   // extra guard

    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:list.count];

    for (id obj in list) {

        if (isFeed && [SCIUtils getBoolPref:@"no_suggested_post"]) {

            // Posts
            if ([obj isKindOfClass:%c(IGMedia)]) {
                // isOrganicMedia
                BOOL organic = SCISendBool(obj, @selector(isOrganicMedia));
                if (!organic) {
                    NSLog(@"[SCInsta] Removing suggested posts");
                    continue;
                }
            }

            // Header title
            if ([obj isKindOfClass:%c(IGFeedGroupHeaderViewModel)]) {
                NSString *title = SCISendId(obj, @selector(title));
                if ([title isKindOfClass:[NSString class]] && [title isEqualToString:@"Suggested Posts"]) {
                    NSLog(@"[SCInsta] Removing suggested posts");
                    continue;
                }
            }

            if ([obj isKindOfClass:%c(IGInFeedStoriesTrayModel)]) {
                NSLog(@"[SCInsta] Hiding suggested stories carousel");
                continue;
            }
        }

        if (isFeed && [SCIUtils getBoolPref:@"no_suggested_reels"]) {
            if ([obj isKindOfClass:%c(IGFeedScrollableClipsModel)]) {
                NSLog(@"[SCInsta] Hiding suggested reels carousel");
                continue;
            }
        }

        if ([SCIUtils getBoolPref:@"hide_ads"]) {

            // IGFeedItem sponsor flags
            if ([obj isKindOfClass:%c(IGFeedItem)]) {
                BOOL sponsored = SCISendBool(obj, @selector(isSponsored));
                BOOL sponsoredApp = SCISendBool(obj, @selector(isSponsoredApp));
                if (sponsored || sponsoredApp) {
                    NSLog(@"[SCInsta] Removing ads");
                    continue;
                }
            }

            // Discovery grid model
            if ([obj isKindOfClass:%c(IGDiscoveryGridItem)]) {
                id model = SCISendId(obj, @selector(model));
                if (model && [model isKindOfClass:%c(IGAdItem)]) {
                    NSLog(@"[SCInsta] Removing ads");
                    continue;
                }
            }

            if ([obj isKindOfClass:%c(IGAdItem)]) {
                NSLog(@"[SCInsta] Removing ads");
                continue;
            }
        }

        [filteredObjs addObject:obj];
    }

    return [filteredObjs copy];
}

// Suggested posts/reels
%hook IGMainFeedListAdapterDataSource
- (NSArray *)objectsForListAdapter:(id)arg1 {
    return removeItemsInList(%orig, YES);
}
%end
%hook IGSundialFeedDataSource
- (NSArray *)objectsForListAdapter:(id)arg1 {
    return removeItemsInList(%orig, NO);
}
%end
%hook IGContextualFeedViewController
- (NSArray *)objectsForListAdapter:(id)arg1 {
    if ([SCIUtils getBoolPref:@"hide_ads"]) {
        return removeItemsInList(%orig, NO);
    }

    return %orig;
}
%end
%hook IGVideoFeedViewController
- (NSArray *)objectsForListAdapter:(id)arg1 {
    if ([SCIUtils getBoolPref:@"hide_ads"]) {
        return removeItemsInList(%orig, NO);
    }

    return %orig;
}
%end
%hook IGChainingFeedViewController
- (NSArray *)objectsForListAdapter:(id)arg1 {
    if ([SCIUtils getBoolPref:@"hide_ads"]) {
        return removeItemsInList(%orig, NO);
    }

    return %orig;
}
%end
%hook IGStoryAdPool
- (id)initWithUserSession:(id)arg1 {
    if ([SCIUtils getBoolPref:@"hide_ads"]) {
        NSLog(@"[SCInsta] Removing ads");

        return nil;
    }

    return %orig;
}
%end
%hook IGStoryAdsManager
- (id)initWithUserSession:(id)arg1 storyViewerLoggingContext:(id)arg2 storyFullscreenSectionLoggingContext:(id)arg3 viewController:(id)arg4 {
    if ([SCIUtils getBoolPref:@"hide_ads"]) {
        NSLog(@"[SCInsta] Removing ads");

        return nil;
    }

    return %orig;
}
%end
%hook IGStoryAdsFetcher
- (id)initWithUserSession:(id)arg1 delegate:(id)arg2 {
    if ([SCIUtils getBoolPref:@"hide_ads"]) {
        NSLog(@"[SCInsta] Removing ads");

        return nil;
    }

    return %orig;
}
%end
// IG 148.0
%hook IGStoryAdsResponseParser
- (id)parsedObjectFromResponse:(id)arg1 {
    if ([SCIUtils getBoolPref:@"hide_ads"]) {
        NSLog(@"[SCInsta] Removing ads");

        return nil;
    }

    return %orig;
}
- (id)initWithReelStore:(id)arg1 {
    if ([SCIUtils getBoolPref:@"hide_ads"]) {
        NSLog(@"[SCInsta] Removing ads");

        return nil;
    }

    return %orig;
}
%end
%hook IGStoryAdsOptInTextView
- (id)initWithBrandedContentStyledString:(id)arg1 sponsoredPostLabel:(id)arg2 {
    if ([SCIUtils getBoolPref:@"hide_ads"]) {
        NSLog(@"[SCInsta] Removing ads");

        return nil;
    }

    return %orig;
}
%end
%hook IGSundialAdsResponseParser
- (id)parsedObjectFromResponse:(id)arg1 {
    if ([SCIUtils getBoolPref:@"hide_ads"]) {
        NSLog(@"[SCInsta] Removing ads");

        return nil;
    }

    return %orig;
}
- (id)initWithMediaStore:(id)arg1 userStore:(id)arg2 {
    if ([SCIUtils getBoolPref:@"hide_ads"]) {
        NSLog(@"[SCInsta] Removing ads");
        
        return nil;
    }
    
    return %orig;
}
%end
// "Sponsored" posts on discover/search page
%hook IGExploreListKitDataSource
- (NSArray *)objectsForListAdapter:(id)arg1 {
    if ([SCIUtils getBoolPref:@"hide_ads"]) {
        return removeItemsInList(%orig, NO);
    }

    return %orig;
}
%end

// Hide shopping carousel in reel comments
// Demangled name: IGCommentThreadCommerceCarouselPill.IGCommentThreadCommerceCarousel
%hook _TtC35IGCommentThreadCommerceCarouselPill31IGCommentThreadCommerceCarousel
- (id)initWithFrame:(CGRect)frame pillText:(id)text pillStyle:(NSInteger)style {
    if ([SCIUtils getBoolPref:@"hide_ads"]) {
        return nil;
    }

    return %orig(frame, text, style);
}
%end

// Hide suggested search/shopping on reels

// Demangled name: IGShoppableEverythingCommon.IGRapEntrypointResolver
%hook _TtC27IGShoppableEverythingCommon23IGRapEntrypointResolver
- (id)initWithLauncherSet:(id)arg1 {
    if ([SCIUtils getBoolPref:@"hide_ads"]) {
        return nil;
    }

    return %orig(arg1);
}
%end
// Demangled name: IGSundialOrganicCTAContainerView.IGSundialOrganicCTAContainerView
%hook _TtC32IGSundialOrganicCTAContainerView32IGSundialOrganicCTAContainerView
- (void)didMoveToWindow {
    %orig;

    if ([SCIUtils getBoolPref:@"hide_ads"]) {
        [self removeFromSuperview];
    }
}
%end


// Hide "suggested for you" text at end of feed
%hook IGEndOfFeedDemarcatorCellTopOfFeed
- (void)configureWithViewConfig:(id)arg1 {
    %orig;

    if ([SCIUtils getBoolPref:@"no_suggested_post"]) {
        NSLog(@"[SCInsta] Hiding end of feed message");

        // Hide suggested for you text
        UILabel *_titleLabel = MSHookIvar<UILabel *>(self, "_titleLabel");

        if (_titleLabel != nil) {
            [_titleLabel setText:@""];
        }
    }

    return;
}
%end