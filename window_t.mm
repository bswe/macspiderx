#import "window_t.h"


void set_pref(const NSString* key, int value)
	{
	CFNumberRef num = CFNumberCreate(NULL, kCFNumberIntType, &value);
	CFPreferencesSetAppValue((CFStringRef) key, num, kCFPreferencesCurrentApplication);
	CFRelease(key);
	CFRelease(num);
	CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
	}

int get_pref(const NSString* key)
	{
	CFNumberRef num;
	int value;
	
	num = (CFNumberRef) CFPreferencesCopyAppValue((CFStringRef) key, kCFPreferencesCurrentApplication);   
	
	if (num)
		{
		if (!CFNumberGetValue(num, kCFNumberIntType, &value)) 
			{
			value = 0;
			}
		CFRelease(num);
		}
	else  //pref not found, set the default
		{
		set_pref(key, 0);
		}

	CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
	return value;
	}


@implementation window_t

// add this to close application when window is closed
- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) theApplication {
    return YES;
}

- (IBAction) deal: (id) sender
{
	[gl_view deal];
	time = 0;
	//redraw the view
	[gl_view drawRect:[gl_view frame]];
}

- (IBAction) undo: (id) sender
{
	[gl_view undo];
	time = 0;
	//redraw the view
	[gl_view drawRect:[gl_view frame]];
}

- (IBAction) set_draw: (id) sender
	{
	set_pref(@"draw", [sender selectedRow]);
	if (gl_view->prefs.draw_three != get_pref(@"draw"))
		{
		gl_view->prefs.draw_three = get_pref(@"draw");
		[self deal:self];
		return;
		}
	gl_view->prefs.draw_three = get_pref(@"draw");
	}

- (IBAction) set_scoring: (id) sender
	{
	set_pref(@"scoring", [sender selectedRow]);
	if (get_pref(@"scoring") == 0)
		{
		set_pref(@"cumulative", false);
		[cumulative_checkbox setState: NSOffState];
		[cumulative_checkbox setEnabled:false];
		}
	else if (get_pref(@"scoring") == 1)
		{
		[cumulative_checkbox setEnabled:true];
		}
	else //vegas
		{
		[cumulative_checkbox setEnabled:true];
		}
	if (gl_view->prefs.scoring != get_pref(@"scoring"))
		{
		gl_view->prefs.scoring = get_pref(@"scoring");
		[self deal:self];
		return;
		}
	
	gl_view->prefs.scoring = get_pref(@"scoring");
	}

- (IBAction) set_deck: (id) sender
	{
	set_pref(@"deck", [sender selectedColumn]);
	gl_view->prefs.deck = get_pref(@"deck");
	[gl_view load_deck_texture:true];
	}

- (IBAction) set_timed: (id) sender
	{
	if ([sender state] == NSOnState)
		set_pref(@"timed", true);
	else
		set_pref(@"timed", false);
	
	gl_view->prefs.timed = get_pref(@"timed");
	}

- (IBAction) set_cumulative: (id) sender
	{
	if ([sender state] == NSOnState)
		set_pref(@"cumulative", true);
	else
		set_pref(@"cumulative", false);
	
	gl_view->prefs.cumulative = get_pref(@"cumulative");
	}

- (IBAction) show_prefs: (id) sender
	{
	[prefs_window makeKeyAndOrderFront: self];
	}

- (void) load_prefs
	{
	gl_view->prefs.deck = get_pref(@"deck");
	[gl_view load_deck_texture:false];
	
	gl_view->prefs.timed = get_pref(@"timed");
	[timed_checkbox setState:gl_view->prefs.timed ? NSOnState : NSOffState];
	
	gl_view->prefs.cumulative = get_pref(@"cumulative");
	[cumulative_checkbox setState: gl_view->prefs.cumulative ? NSOnState : NSOffState];
	
	gl_view->prefs.scoring = get_pref(@"scoring");
	[scoring_combo selectCellAtRow:gl_view->prefs.scoring column:0];
	
	gl_view->prefs.draw_three = get_pref(@"draw");
	[draw_combo selectCellAtRow:gl_view->prefs.draw_three column:0];
	
	if (gl_view->prefs.scoring == 0) //no scoring
		{
		[cumulative_checkbox setEnabled:false];
		[score_text setStringValue:@""];
		}
	else if (gl_view->prefs.scoring == 1) //normal scoring
		{
		[cumulative_checkbox setEnabled:false];		
		}
	else //scoring == 2 (vegas)
		{
		[cumulative_checkbox setEnabled:true];
		}

	}

- (void) awakeFromNib
	{
	std::clog << "awakeFromNib: " << "\n";
	[NSApp setDelegate:self];
	timer = nil;	
	[window makeFirstResponder:self];
	//[window setDelegate:self];
	
	NSRect frame = [custom_view frame];
	gl_view = [[opengl_t alloc] initWithFrame:frame colorBits:32 depthBits:32];  

	//can only load prefs after gl_view had been alloc'ed
	[self load_prefs];
	
	//deal the original hand
	[gl_view deal];	

	[custom_view setContentView:gl_view];
	[window makeKeyAndOrderFront:self];
	
	[self setup_timer];
	}


- (void) setup_timer
	{
	std::clog << "setup_timer: adding timers\n";
	timer = [[NSTimer scheduledTimerWithTimeInterval:.25 target:self selector:@selector(update:) userInfo:nil repeats:YES] retain];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSModalPanelRunLoopMode];
	}


- (void) update: (NSTimer*) timer
	{
	time++;
	
	if (gl_view->won)
		{
		gl_view->won = false;
		//[gl_view start_win_anim];
		//use a sheet to tell the user they won.
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Congrats."];
		[alert setInformativeText:@"You win!"];
		[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
		}
		
	if (gl_view->userMessage.message != "") {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"OK"];
		NSString *nsString = [NSString stringWithCString:gl_view->userMessage.message.c_str() encoding:[NSString defaultCStringEncoding]];
		[alert setMessageText:nsString];
		nsString = [NSString stringWithCString:gl_view->userMessage.info.c_str() encoding:[NSString defaultCStringEncoding]];
		[alert setInformativeText:nsString];
		[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:nil];
		gl_view->userMessage.message = "";
		return;
		}
	
	//[gl_view start_win_anim];
	
	if (gl_view->prefs.scoring == 0)
		{
		if (gl_view->prefs.timed)
			[score_text setStringValue: [NSString stringWithFormat:@"Time: %i", time/4]];
		else
			[score_text setStringValue:@""];
		return;
		}
	
	NSString* s = [NSString stringWithString:@"Score: "];
	if (gl_view->prefs.scoring == 1)
		s = [s stringByAppendingFormat:@"%i", gl_view->score];
	else
		s = [s stringByAppendingFormat:@"$%i", gl_view->score];
	
	if (gl_view->prefs.timed)
		[score_text setStringValue: [s stringByAppendingFormat:@"  Time: %i", time/4]];
	else
		[score_text setStringValue: s];
	
	}


- (void) createFailed
	{ 
	NSWindow *infoWindow;	
	infoWindow = NSGetCriticalAlertPanel( @"Initialization failed", @"Failed to initialize OpenGL", @"OK", nil, nil);
	[NSApp runModalForWindow:infoWindow];
	[infoWindow close];
	[NSApp terminate:self];
	}


- (void) dealloc
	{
	[window release];
	[gl_view release];
	if (timer != nil && [timer isValid])
		[timer invalidate];
	[super dealloc];
	}

#pragma mark -
#pragma mark Delegate 
#pragma mark -

- (void) windowWillMiniaturize:(NSNotification *)aNotification
	{
	std::clog << "about to mini-ize\n";
	[gl_view mini_ize];
	}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode
	   contextInfo:(void *)contextInfo
	{
	//[gl_view stop_win_anim];
	[gl_view deal];
	}

@end
