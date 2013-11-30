#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#include <vector>
#include <iostream>
#include <algorithm>

#define CARD_WIDTH              71  // 90.0f * .75
#define CARD_HEIGHT             96  // 130.0f * .75
#define XPAD                    15
#define NUMBER_OF_STACKS        10
#define NUMBER_OF_FULL_SUITS    8
#define NUMBER_OF_CARDS_IN_DECK 52
#define NUMBER_OF_CARDS_IN_SUIT 13
#define NUMBER_OF_DECKS_IN_GAME 2
#define NUMBER_OF_SUITS_IN_DECK 4
#define NUMBER_OF_SHUFFLES      6

struct texture_t {
	GLubyte* data;
	GLuint bpp;
	GLuint w;
	GLuint h;
	GLuint texture_id;
	GLuint type;
	};

struct prefs_t {
	bool timed;
	bool draw_three;
	int scoring;
	bool cumulative;
	int deck;
	};

struct card_t {
	int suit;
	int number;
	bool faceup;
	int x, y;
	};

struct move_t {
	int fromStack;
	int toStack;
	int numberOfCardsMoved;
	bool wasCardAboveFaceup;
    };

struct user_message_t {
	std::string message;
	std::string info;
    };

bool hits_card (int x, int y, card_t card);
bool hits_card (int x, int y, card_t card, bool IncludeColumn);

@interface opengl_t : NSOpenGLView {
	int colorBits, depthBits;
	
	std::vector<card_t> Stacks[NUMBER_OF_STACKS];
	std::vector<card_t> FullSuits[NUMBER_OF_FULL_SUITS];
	std::vector<card_t> Deck;
	std::vector<card_t> CardsBeingDragged;
	std::vector<move_t> Moves;
	
	texture_t card_textures[NUMBER_OF_CARDS_IN_DECK];
	texture_t back_texture;
	texture_t empty_texture;
	texture_t top_empty_texture;
	texture_t top_x_texture;
	
	int StackCardsFrom; // the stack that the CardsBeingDragged came from
	int x,y;            // absolute position of the mouse
	
	@public
	int score;
	bool won;
	int xoff, yoff;
	user_message_t userMessage;
	prefs_t prefs;
    }

- (id) initWithFrame: (NSRect)frame colorBits:(int)numColorBits
       depthBits: (int)numDepthBits;
- (void) undo;
- (void) deal;
- (void) reshape;
- (void) drawRect: (NSRect)rect;
- (void) dealloc;
- (void) load_deck_texture: (bool) redraw;
- (void) mini_ize;
- (void) start_win_anim;
//- (void) stop_win_anim;
- (void) draw_card: (int)x y:(int)y card:(card_t*)card;
- (void) load_texture: (texture_t*) texture filename: (NSString*) filename replace: (bool) replace;
- (NSOpenGLPixelFormat *) createPixelFormat: (NSRect)frame;
- (bool) init_gl;
- (bool) load_textures;

@end

@interface opengl_t (mouse)

- (void) PickupCards: (int) Stack: (int) Card;
- (void) DoHitTest;
- (void) AddMove: (int) _fromStack: (int) _toStack: (int) _position;
- (int) SizeOfSequentialSameSuitCards: (int) Stack;  
- (void) mouseDown: (NSEvent*) event;
- (void) rightMouseDown: (NSEvent*) event;

@end

