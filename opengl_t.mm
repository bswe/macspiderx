#import "opengl_t.h"
#include <ctime>

// random generator function:
int MyRandom (int i) { 
	return std::rand() % (NUMBER_OF_CARDS_IN_DECK * NUMBER_OF_DECKS_IN_GAME);
    }

@implementation opengl_t

- (void) undo {
	if (Moves.size() == 0) {
		std::clog << "undo: no moves left to undo\n";
		return;
	    }	
	std::clog << "undo: " << Moves.size() << " moves left to undo\n";
	
	std::clog << "undo: fromStack=" << Moves.back().fromStack 
	          << ", toStack=" << Moves.back().toStack 
	          << ", numberOfCardsMoved=" << Moves.back().numberOfCardsMoved 
	          << ", wasCardAboveFaceup=" << Moves.back().wasCardAboveFaceup << "\n";
	
	if (Moves.back().numberOfCardsMoved == 0) {
		// cards were dealt, so un-deal them
		for (int Stack = NUMBER_OF_STACKS-1; Stack >= 0; Stack--) {
			Deck.push_back(Stacks[Stack].back());
			Deck.back().faceup = false;
			Stacks[Stack].pop_back();
		    }
		Moves.pop_back();
		return;
	    }
	
	// not a card deal, so undo a move
	int toStack = Moves.back().toStack;
	int fromStack = Moves.back().fromStack;
	Stacks[fromStack].back().faceup = Moves.back().wasCardAboveFaceup;
	
	if (Moves.back().numberOfCardsMoved < 0) {
		// move was to a FullSuit pile
		Moves.back().numberOfCardsMoved *= -1;
		int topCard = FullSuits[toStack].size() - Moves.back().numberOfCardsMoved;
		for (int Card=topCard; Card < (int) FullSuits[toStack].size(); Card++) {
		    Stacks[fromStack].push_back(FullSuits[toStack][Card]);
		    std::clog << "adding FullSuits[" << toStack << "][" << Card << "] to Stacks[" << fromStack << "]\n";
			}
	    FullSuits[toStack].erase(FullSuits[toStack].begin()+topCard, FullSuits[toStack].begin()+FullSuits[toStack].size());
		}
	else {
		// move was to another card pile
		int topCard = Stacks[toStack].size() - Moves.back().numberOfCardsMoved;
		for (int Card=topCard; Card < (int) Stacks[toStack].size(); Card++) {
		    Stacks[fromStack].push_back(Stacks[toStack][Card]);
		    std::clog << "adding Stacks[" << toStack << "][" << Card << "] to Stacks[" << fromStack << "]\n";
		    }
	    Stacks[toStack].erase(Stacks[toStack].begin()+topCard, Stacks[toStack].begin()+Stacks[toStack].size());
	    }
	Moves.pop_back();
    }

- (void) deal {
	// clear out any possible old cards
	Deck.clear();	
	CardsBeingDragged.clear();
	Moves.clear();
	
	for (int i = 0; i < NUMBER_OF_FULL_SUITS; i++)
		FullSuits[i].clear();
	
	for (int i = 0; i < NUMBER_OF_STACKS; i++)
		Stacks[i].clear();

	
	x = 0; y = 0;
	if (prefs.cumulative == false) {
		score = 0;
		if (prefs.scoring == 2)
			score -= NUMBER_OF_CARDS_IN_DECK;  // vegas scoring
		}
	else if (prefs.scoring == 2)
		score -= NUMBER_OF_CARDS_IN_DECK;  // vegas scoring
	
	won = false;
	userMessage.message = "";
	
	Deck.reserve(NUMBER_OF_CARDS_IN_DECK * NUMBER_OF_DECKS_IN_GAME);
	
	for (int i = 0; i < NUMBER_OF_CARDS_IN_DECK * NUMBER_OF_DECKS_IN_GAME; i++) {
		card_t card;
		card.suit = (i / NUMBER_OF_CARDS_IN_SUIT) % NUMBER_OF_SUITS_IN_DECK;
		card.number = i % NUMBER_OF_CARDS_IN_SUIT;
		card.faceup = false;
		std::clog << "deal: card.suit = " << card.suit << " card.number = " << card.number << "\n";
		Deck.push_back(card);
		}
		
	std::clog << "deal: # of cards " << Deck.size() << "\n";
	
	// seed the prng
	std::srand((unsigned int) std::time(0));
	
	// shuffle the cards
	for (int i=0; i < NUMBER_OF_SHUFFLES; i++)
		std::random_shuffle (Deck.begin(), Deck.end(), MyRandom);

	// insert dummy card into front of card pile
	card_t c;
	if ((prefs.scoring == 2) && (!prefs.draw_three))
		c.suit = 1001;
	else
		c.suit = 1000;
	c.number = 0;
	c.faceup = true;
	Deck.insert(Deck.begin(), c);
	
	// deal the cards to the stacks
	for (int Stack = 0; Stack < NUMBER_OF_STACKS; Stack++) {
		int StackSize;
			
		// add a dummy card to the Stacks
		c.suit = 100;
		c.number = 100;
		c.faceup = false;
		Stacks[Stack].push_back(c);
			
		if (Stack % 3 == 0)
			StackSize = 6;
		else 
			StackSize = 5;

		for (int Card = 0; Card < StackSize; Card++) {
			std::clog << "deal:" << Stack << Deck.back().suit << "  " << Deck.back().number << "\n";
			Stacks[Stack].push_back(Deck.back());
			Deck.pop_back();
			}
		Stacks[Stack].back().faceup = true;
		}
	
	// add a dummy card to the FullSuits
	for (int i = 0; i < NUMBER_OF_FULL_SUITS; i++) {
		card_t c;
		c.suit = 10;
		c.number = i;
		c.faceup = true;
		FullSuits[i].push_back(c);
		}
		
	}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits 
		depthBits:(int)numDepthBits {
	NSOpenGLPixelFormat* pixel_format;
	
	colorBits = numColorBits;
	depthBits = numDepthBits;
	
	pixel_format = [self createPixelFormat:frame];
	
	self = [super initWithFrame:frame pixelFormat:pixel_format];
	[pixel_format release];
	if (self) {
		[[self openGLContext] makeCurrentContext];
		[ self reshape ];
		if (![ self init_gl]) {
			[self clearGLContext];
			self = nil;
			}
		}
	
	return self;
	}

- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame {
	NSOpenGLPixelFormatAttribute pixel_attributes[16];
	NSOpenGLPixelFormat *pixel_format;
	
	pixel_attributes[0] = NSOpenGLPFADoubleBuffer;
	pixel_attributes[1] = NSOpenGLPFAAccelerated;
	pixel_attributes[2] = NSOpenGLPFAColorSize;
	pixel_attributes[3] = (NSOpenGLPixelFormatAttribute) colorBits;
	pixel_attributes[4] = NSOpenGLPFADepthSize;
	pixel_attributes[5] = (NSOpenGLPixelFormatAttribute) depthBits;	
	pixel_attributes[6] = (NSOpenGLPixelFormatAttribute) 0;
	
	pixel_format = [[NSOpenGLPixelFormat alloc] initWithAttributes:pixel_attributes];
	
	return pixel_format;
	}


- (bool) init_gl {
	if (![self load_textures])
		return false;
	
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glClearColor(0.0f, 0.5f, 0.0f, 0.5f);
	return true;
	}

- (void) load_texture: (texture_t*) texture filename: (NSString*) filename  replace: (bool) replace {
	NSBitmapImageRep *btmp = [NSBitmapImageRep imageRepWithContentsOfFile: filename];
	texture->h = [btmp pixelsHigh];
	texture->w = [btmp pixelsWide];
	texture->bpp = [btmp bitsPerPixel];
	
	if (texture->bpp == 24)
		texture->type = GL_RGB;
	else if (texture->bpp == 32)
		texture->type = GL_RGBA;
	
	
	if (!replace)
		glGenTextures(1, &texture->texture_id);
	
	glBindTexture(GL_TEXTURE_2D, texture->texture_id);
	
	// doh! don't forget textures need to be 2^n height/width!!
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texture->w,
			   texture->h, 0, texture->type, GL_UNSIGNED_BYTE,
			   [btmp bitmapData] );
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	//glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
	
	//[btmp autorelease]; //not sure if this is needed
	}


- (void) load_deck_texture : (bool) redraw {
	// load the back (deck) texture
	NSString* path = [[NSBundle mainBundle] resourcePath];
	NSString* str = [[NSString alloc] init];
	str = [path stringByAppendingFormat:@"/back%i", prefs.deck+1];
	str = [str stringByAppendingString:@".png"];
	[self load_texture: &back_texture filename:str replace:true];
	if (redraw)
		[self drawRect:[self frame]];
	//[self load_texture: &back_texture filename: @"/Users/elitehaxor/Desktop/classic-cards/b1fv.png"];
	}
		

- (bool) load_textures {	
	NSString* path = [[NSBundle mainBundle] resourcePath];
	[self load_deck_texture:false];
	
	// load the empty "O" texture
	[self load_texture: &empty_texture filename: [path stringByAppendingString: @"/empty.png"] replace:false];
	
	// load the empty "X" texture
	[self load_texture: &top_x_texture filename: [path stringByAppendingString:@"/empty_x.png"] replace:false];
	
	// load the top stack empty texture
	[self load_texture: &top_empty_texture filename: [path stringByAppendingString:@"/top_empty.png"] replace:false];
	
		
	// load the NUMBER_OF_CARDS_IN_DECK standard card textures
	for (int i = 0; i < NUMBER_OF_CARDS_IN_DECK; i++) {
		NSString* str = [[NSString alloc] init];
		str = [path stringByAppendingFormat:@"/%i", i+1];
		str = [str stringByAppendingString:@".png"];
		[self load_texture: &card_textures[i] filename:str replace:false];
		}  

	return true;
	}

- (void) mini_ize {
	// FIXME
	
	GLubyte* data = (GLubyte*) malloc(sizeof(GLubyte) * 3 * [self bounds].size.width * [self bounds].size.height);
	glReadBuffer(GL_FRONT);
	glReadPixels(0, 0, [self bounds].size.width, [self bounds].size.height, GL_RGB, GL_UNSIGNED_BYTE, data);
	GLubyte* buf = (GLubyte*) malloc(sizeof(GLubyte) * 3 * [self bounds].size.width);
	int h = [self bounds].size.height;
	int w = [self bounds].size.width;
	
	std::clog << "mini_ize: " << w << "\n";
	for (int i = 0; i < h / 2; i++) { //image flip
		memcpy((void*)buf,(const void*)&data[i * 3 * w], 3 * w);
		memcpy((void*)&data[i * (3 * w)], (const void*)&data[ ((h-1) - i) * (3 * w)], 3 * w);
		memcpy((void*)&data[ ((h-1) - i) * (3 * w)], (const void*)buf, 3 * w);
		}
	//for (int i = 0; i < 323; i++)
	//    std::clog << (int) data[i] << "-";
	NSBitmapImageRep* btmp = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: &data pixelsWide:[self bounds].size.width pixelsHigh:[self bounds].size.height
													  bitsPerSample: 8 samplesPerPixel: 3 hasAlpha: false isPlanar: false colorSpaceName: NSDeviceRGBColorSpace 
													    bytesPerRow: [self bounds].size.width * 3 bitsPerPixel: 24];
	bool b = [btmp drawInRect:[self bounds]];
	std::clog << "drawing returned :" << b << "\n";
	[btmp release];
	free(data);
	free(buf);
	}

- (void) reshape {
	int w = (int) [self bounds].size.width;
	int h = (int) [self bounds].size.height;
	
	std::clog << "reshape: " << w << " " << h << "\n";
	glViewport(0, 0, (GLsizei) [self bounds].size.width, (GLsizei) [self bounds].size.height);	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();	
	glOrtho(-w/2., w/2., -h/2., h/2., 1.0f, -10.0f);   
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	}

- (void) draw_card:(int)_x y:(int)_y card:(card_t*)card {
	glPushMatrix();
	glLoadIdentity();
	
	card->x = _x;
	card->y = _y;
	
	//std::clog << "draw_card: bounds.size.width=" << [self bounds].size.width << ", bounds.size.height=" << [self bounds].size.height 
	//          << ", _x=" << _x << ", _y=" << _y << "\n";
	glTranslatef(_x - [self bounds].size.width/2, _y - [self bounds].size.height/2, 0.);

	if (card->suit == 100) {
		glPopMatrix();
		return;
		}

	if (card->faceup) {
		//glColor3f(1.0f, .5f, .5f);
		if (card->suit == 10)
			glBindTexture(GL_TEXTURE_2D, top_empty_texture.texture_id);  //empty tstack texture
		else if (card->suit == 1000)
			glBindTexture(GL_TEXTURE_2D, empty_texture.texture_id);  //empty main pile texture (green O)
		else if (card->suit == 1001)
			glBindTexture(GL_TEXTURE_2D, top_x_texture.texture_id);  //empty main pile texture (red X)
		else if (card->number == 0)
			glBindTexture(GL_TEXTURE_2D, card_textures[card->suit].texture_id);
		else
			glBindTexture(GL_TEXTURE_2D, card_textures[card->suit + (NUMBER_OF_CARDS_IN_SUIT-card->number)*4 ].texture_id);
		}
	else {
		//glColor3f(.5f, .5f, 1.0f);
		glBindTexture(GL_TEXTURE_2D, back_texture.texture_id);
		}
	
	float h = CARD_HEIGHT;
	float w = CARD_WIDTH;
	
	float tx = 71./128.;
	float ty = 96./128.;
	
	glBegin(GL_QUADS);
		glTexCoord2f(0.0f, 0.0f);
		glVertex3f(0.f,  0., 0.0f);
		glTexCoord2f(tx, 0.0f);
		glVertex3f(w,  0., 0.0f);
		glTexCoord2f(tx, ty);
		glVertex3f(w, -h, 0.0f);
		glTexCoord2f(0.0f, ty);
		glVertex3f(0.f, -h, 0.0f);
	glEnd();   
	
	glPopMatrix();
	}

- (void) start_win_anim
	{
	// TODO
	/*for (int _i = 0; _i < 16; _i++)
		{
		glLoadIdentity();
		float pad = (([self bounds].size.width - (CARD_WIDTH + XPAD*2)) / 6.0f);
		
		for (int i = 0; i < NUMBER_OF_FULL_SUITS; i++)
			{
			static float xp = 0;
			//static float dyp = 5;
			static float yp = 0;
			for (int z = 1; z < (int) FullSuits[i].size(); z++)
				{
				[self draw_card:(int) FullSuits[i][z].x + (3*(z-7))
						    y:(int) FullSuits[i][z].y + (2*(z-6))
						 card:&(FullSuits[i][z])];
				}
			//dyp -= .05f;
			//xp += .2;
			//yp += dyp;
			}
		usleep(1000 * 80);
		
		[[self openGLContext] flushBuffer];
		}
	*/
	}

- (void) drawRect:(NSRect)rect 	{
	std::clog << "drawRect: " << "\n";
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity(); 
	
	bool _won = true;
	for (int i = 0; i < NUMBER_OF_FULL_SUITS; i++) {
		if (FullSuits[i].size() <= NUMBER_OF_CARDS_IN_SUIT)
			_won = false;
		}
	if (_won) {
		std::clog << "you have won.\n";
		won = true;
		}

	float pad = (([self bounds].size.width - (CARD_WIDTH + XPAD*2)) / 9.0f);
	
	// draw stacks
	for (int Stack = 0; Stack < NUMBER_OF_STACKS; Stack++) {
		int offs = (int) [self bounds].size.height - (CARD_HEIGHT + 2*XPAD);
		for (int Card = 0; Card < (int) Stacks[Stack].size(); Card++) {
			[self draw_card:(int) XPAD + Stack*pad y:(int) offs card:&Stacks[Stack][Card]];
			
			if (Stacks[Stack][Card].faceup)
				offs -= 20;
			else
				offs -= 5;			
			}
		}
	
	// draw full suits
	for (int Stack = 0; Stack < NUMBER_OF_FULL_SUITS; Stack++) {
		[self draw_card:(int) XPAD + pad*2 + pad*Stack 
		 y:(int) [self bounds].size.height - XPAD
		 card:&(FullSuits[Stack].back())];
		}
	
	// draw main pile
	if (Deck.size()) 
		for (int n=0, i=(Deck.size())-((int)Deck.size()/10); i < (int) Deck.size(); n++, i++) 
			[self draw_card:(int) XPAD + n*5 y:(int) [self bounds].size.height - (XPAD + n) card:&Deck[i]];
	
    // if we are dragging a card stack, draw it:
	if (CardsBeingDragged.size()) {
		for (int i = 0; i < (int) CardsBeingDragged.size(); i++)
			[self draw_card:x-xoff y:(i*-20)+y+yoff card:&(CardsBeingDragged[i])];
		}
		
	[[self openGLContext] flushBuffer];
	}


- (void) dealloc {
	[super dealloc];
	}

@end
