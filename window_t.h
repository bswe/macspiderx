
#import <Cocoa/Cocoa.h>
#import "opengl_t.h"

@interface window_t : NSResponder
{
	IBOutlet NSWindow* window;
	IBOutlet NSWindow* prefs_window;
	IBOutlet NSBox* custom_view;
	IBOutlet NSTextField* score_text;
	IBOutlet NSButton* cumulative_checkbox;
	IBOutlet NSButton* timed_checkbox;
	IBOutlet NSMatrix* draw_combo;
	IBOutlet NSMatrix* scoring_combo;
	IBOutlet NSMatrix* deck_combo;
		
	NSTimer *timer;
	opengl_t *gl_view;
	int time;
}

- (IBAction) deal: (id) sender;
- (IBAction) undo: (id) sender;
- (IBAction) set_timed: (id) sender;
- (IBAction) set_scoring: (id) sender;
- (IBAction) set_deck: (id) sender;
- (IBAction) set_draw: (id) sender;
- (IBAction) set_cumulative: (id) sender;
- (IBAction) show_prefs: (id) sender;
- (void) windowWillMiniaturize:(NSNotification *)aNotification;
- (void) alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode
	   contextInfo:(void *)contextInfo;
- (void) load_prefs;
- (void) awakeFromNib;
- (void) dealloc;
- (void) setup_timer;

@end
