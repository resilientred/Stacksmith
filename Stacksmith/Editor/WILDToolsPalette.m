//
//  WILDToolsPalette.m
//  Stacksmith
//
//  Created by Uli Kusterer on 11.05.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDToolsPalette.h"
#import "WILDTools.h"
#import "UKBorderlessWindow.h"
#import "UKHelperMacros.h"


NSString*		WILDToolsPaletteVisibleKey = @"WILDToolsPaletteVisible";


@implementation WILDToolsPalette

static WILDToolsPalette*	sSharedToolsPalette = nil;

@synthesize lineColorWell = mLineColorWell;
@synthesize fillColorWell = mFillColorWell;

+(void)	showToolsPaletteIfNeeded
{
	BOOL			shouldBeVisible = YES;
	NSNumber	*	shouldBeVisibleObj = [[NSUserDefaults standardUserDefaults] objectForKey:WILDToolsPaletteVisibleKey];
	if( shouldBeVisibleObj )
		shouldBeVisible = [shouldBeVisibleObj boolValue];
	
	if( shouldBeVisible )
		[[self sharedToolsPalette] orderFrontToolsPalette: self];
}


+(WILDToolsPalette*)	sharedToolsPalette
{
	if( !sSharedToolsPalette )
	{
		sSharedToolsPalette = [[WILDToolsPalette alloc] init];
		[sSharedToolsPalette window];
	}
	
	return sSharedToolsPalette;
}


- (id)init
{
    self = [super initWithWindowNibName: NSStringFromClass([self class])];
    if (self)
	{
        sSharedToolsPalette = self;
    }
    
    return self;
}


-(void)	dealloc
{
	DESTROY_DEALLOC(mLineColorWell);
	DESTROY_DEALLOC(mFillColorWell);
	
    [super dealloc];
}

-(void)	windowDidLoad
{
    [super windowDidLoad];
	
	[[self window] setLevel: NSNormalWindowLevel];
    
	ULIPaintView	* cpv = [ULIPaintView currentPaintView];
	if( cpv )
	{
		[mLineColorWell setColor: [cpv lineColor]];
		[mFillColorWell setColor: [cpv fillColor]];
	}
}

-(void)	orderFrontToolsPalette: (id)sender
{
	ULIPaintView	* cpv = [ULIPaintView currentPaintView];
	if( cpv )
	{
		[mLineColorWell setColor: [cpv lineColor]];
		[mFillColorWell setColor: [cpv fillColor]];
	}
	else
	{
		[mLineColorWell setColor: [NSColor blackColor]];
		[mFillColorWell setColor: [NSColor clearColor]];
	}
	
	[[NSUserDefaults standardUserDefaults] setBool: YES forKey: WILDToolsPaletteVisibleKey];
	CGFloat	toolsHeight = [self.window frame].size.height;
	NSRect	toolsFrame = [[NSScreen.screens objectAtIndex: 0] visibleFrame];
	toolsFrame.origin.y += toolsFrame.size.height -toolsHeight;
	toolsFrame.size.height = toolsHeight;
	[self.window setFrame: toolsFrame display: YES];
	//[self.window setLevel: NSFloatingWindowLevel];
	[(UKBorderlessWindow*)self.window setCanBecomeKeyWindow: YES];
	[(UKBorderlessWindow*)self.window setCanBecomeMainWindow: NO];
	//[self.window setHidesOnDeactivate: NO];
	[[self window] orderFront: sender];
}

-(NSColor*)	lineColor
{
	return [mLineColorWell color];
}


-(NSColor*)	fillColor
{
	return [mFillColorWell color];
}


-(IBAction)	takeLineColorFrom: (NSColorWell*)sender
{
	[[ULIPaintView currentPaintView] takeLineColorFrom: sender];
}


-(IBAction)	takeFillColorFrom: (NSColorWell*)sender
{
	[[ULIPaintView currentPaintView] takeFillColorFrom: sender];
}


-(void)	windowWillClose: (NSNotification*)notif
{
	[[NSUserDefaults standardUserDefaults] setBool: NO forKey: WILDToolsPaletteVisibleKey];
}

@end
