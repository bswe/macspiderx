#import "opengl_t.h"

bool hits_card (int x, int y, card_t card) {
	return hits_card (x, y, card, false);
	}


bool hits_card (int x, int y, card_t card, bool IncludeColumn) {
	if (x < card.x)
		return false;
	if (x > card.x + CARD_WIDTH)
		return false;
	if (y > card.y)
		return false;
	if ((!IncludeColumn) && (y < card.y - CARD_HEIGHT))
		return false;
	
	// if we get here it has hit the card
	return true;
    }



@implementation opengl_t (mouse)


- (void) rightMouseDown: (NSEvent*) event {
	std::clog << "rightMouseDown: right mouse down event occured\n";
	
    return;  // no-op for 1.0 release
	NSPoint mouse;

	mouse = [self convertPoint:[event locationInWindow] fromView:nil];
	
	switch ([event type]) {
		case NSRightMouseDown: {
			std::clog << "right mouse down event notice\n";
			[self mouseDown:[NSEvent mouseEventWithType:NSLeftMouseDown location:[self convertPoint:[event locationInWindow] fromView:nil] modifierFlags:[event modifierFlags]
									    timestamp:[event timestamp] windowNumber:[event windowNumber] context:[event context] 
									  eventNumber:[event eventNumber] clickCount:1 pressure:[event pressure]]];
			[self mouseDown: [NSEvent mouseEventWithType:NSLeftMouseUp location:[self convertPoint:[event locationInWindow] fromView:nil] modifierFlags:[event modifierFlags]
								 timestamp:[event timestamp] windowNumber:[event windowNumber] context:[event context] 
							    eventNumber:[event eventNumber] clickCount:1 pressure:[event pressure]]];
			[self mouseDown: [NSEvent mouseEventWithType:NSLeftMouseDown location:[self convertPoint:[event locationInWindow] fromView:nil] modifierFlags:[event modifierFlags]
										timestamp:[event timestamp] windowNumber:[event windowNumber] context:[event context] 
									   eventNumber:[event eventNumber] clickCount:2 pressure:[event pressure]]];
			[self mouseDown: [NSEvent mouseEventWithType:NSLeftMouseUp location:[self convertPoint:[event locationInWindow] fromView:nil] modifierFlags:[event modifierFlags]
										timestamp:[event timestamp] windowNumber:[event windowNumber] context:[event context] 
									   eventNumber:[event eventNumber] clickCount:2 pressure:[event pressure]]];
				
			}
			break;
		default:
			break;
		}
	}


- (void) AddMove: (int)_fromStack: (int)_toStack: (int)_numberOfCardsMoved {
	move_t Move;
	
	Move.numberOfCardsMoved = _numberOfCardsMoved;
	if (_numberOfCardsMoved == 0) {
		// move was a deal, so just save _numberOfCardsMoved value for undo()
		Moves.push_back(Move);
		return;
	    }
	Move.fromStack = _fromStack;
	Move.toStack = _toStack;
	Move.wasCardAboveFaceup = Stacks[_fromStack].back().faceup;
	std::clog << "AddMove: fromStack=" << Move.fromStack 
	          << ", toStack=" << Move.toStack 
	          << ", numberOfCardsMoved=" << Move.numberOfCardsMoved 
	          << ", wasCardAboveFaceup=" << Move.wasCardAboveFaceup << "\n";
	Moves.push_back(Move);
    }


- (int) SizeOfSequentialSameSuitCards: (int) Stack {
    int Size = 0;   
	
	std::clog << "SizeOfSequentialSameSuitCards: Stack = " << Stack << ", size = " << Stacks[Stack].size() << "\n";
	if (Stacks[Stack].back().faceup == true)
		Size++;
	for (int Card=Stacks[Stack].size()-1; Card > 1; Card--) {
		if (Stacks[Stack][Card-1].faceup == true) {
			std::clog << "SizeOfSequentialSameSuitCards: Card = " << Card << "\n";
			std::clog << "Card suit = " << Stacks[Stack][Card].suit << ", Card # = " << Stacks[Stack][Card].number << "\n";
			std::clog << "Card-1 suit = " << Stacks[Stack][Card-1].suit << ", Card-1 # = " << Stacks[Stack][Card-1].number << "\n";
			if ((Stacks[Stack][Card].suit == Stacks[Stack][Card-1].suit) &&
				(Stacks[Stack][Card].number == Stacks[Stack][Card-1].number-1)) 
				Size++;
			else 
				break;
			}
		else 
			break;
		}
	std::clog << "SizeOfSequentialSameSuitCards: Size = " << Size << "\n";
	return Size;
	}


- (void) DoHitTest {
	std::clog << "DoHitTest: NSLeftMouseDown occured, x=" << x << ", y=" << y << "\n";
	// check for hit on stacks
	for (int Stack = 0; Stack < NUMBER_OF_STACKS; Stack++) 
		for (int Card = (int) Stacks[Stack].size() - 1; Card > 0; Card--) 
			if (hits_card (x, y, Stacks[Stack][Card])) {
				std::clog << "DoHitTest: hit stack " << Stack << " card " << Card << "\n";
				return;
			}
	// check for hit on fullsuits
	for (int i = 0; i < NUMBER_OF_FULL_SUITS; i++) 
		if (hits_card (x, y, FullSuits[i].back())) {
			std::clog << "DoHitTest: hit fullsuit " << i << "\n";
			return;
			}
	if (hits_card (x, y, Deck.back())) {
		std::clog << "DoHitTest: hit deck\n";
		return;
	    }
	for (int Stack = 0; Stack < NUMBER_OF_STACKS; Stack++) 
		if (hits_card (x, y, Stacks[Stack].back(), true)) {
			std::clog << "DoHitTest: hit on stack " << Stack << " column\n";
			return;
		    }
	std::clog << "DoHitTest: didn't hit anything\n";
	}

- (void) PickupCards: (int) Stack: (int) Card {
	xoff = x - Stacks[Stack][Card].x;
	yoff = Stacks[Stack][Card].y - y;
	for (int n=Card; n < (int) Stacks[Stack].size(); n++) {
		CardsBeingDragged.push_back(Stacks[Stack][n]);
		std::clog << "adding Stacks[" << Stack << "][" << n << "] to the CardsBeingDragged list\n";
	    }
	Stacks[Stack].erase(Stacks[Stack].begin()+Card, Stacks[Stack].begin()+Stacks[Stack].size());
	StackCardsFrom = Stack;
    }


- (void) mouseDown: (NSEvent *) event {
	bool MouseButtonUp = false;
	NSPoint mouse;
	
	do {
		mouse = [self convertPoint:[event locationInWindow] fromView:nil];
		
		switch ([event type]) {	
				
			case NSLeftMouseDown: {
				std::clog << "mouseDown: NSLeftMouseDown occured\n";
				
				// perform a hit test to see if the mouse is down somewhere on a card
				x = (int) mouse.x;
				y = (int) mouse.y;
				
				//[self DoHitTest];  return;   // for debugging the position of mouse clicks
				
				// see if it hit on one of the Stacks	
				for (int Stack = 0; Stack < NUMBER_OF_STACKS; Stack++) {
					for (int Card = (int) Stacks[Stack].size() - 1; Card > 0; Card--) {
						if ((Stacks[Stack][Card].faceup) && (hits_card (x, y, Stacks[Stack][Card]))) {
							std::clog << "mouseDown: hit test returned true for card Stacks[" << Stack << "][" << Card << "] with"
							<< " card value of: " << Stacks[Stack][Card].suit << "  " << Stacks[Stack][Card].number << "\n";
							// check to see if all cards on top of card are the same suit and sequential
							for (int C = Card; C < (int) Stacks[Stack].size()-1; C++)
								if ((Stacks[Stack][C].suit != Stacks[Stack][C+1].suit) ||
									(Stacks[Stack][C].number != Stacks[Stack][C+1].number+1)) {
									// all cards on top of clicked card are not of same suit, or not sequential, so discard mouse click
									std::clog << "mouseDown: not same suit or not sequaential, C = " << C << "\n";
									return;
								    }
							[self PickupCards: Stack: Card];
							Stack = NUMBER_OF_STACKS;   // force exit from outer for loop
							break;                      // force exit from inner for loop
							}
						}
					if ((!CardsBeingDragged.size()) && (hits_card (x, y, Stacks[Stack].back(), true))) {
						std::clog << "mouseDown: hit test returned true for card Stacks[" << Stack << "] column" << "\n";
						if (Stacks[Stack].size() > 1) {
							int CardsToMove = [self SizeOfSequentialSameSuitCards:(int) Stack];
							int Card = Stacks[Stack].size() - CardsToMove;
							[self PickupCards: Stack: Card];
							break;                      // force exit from outer for loop
						    }
					    }					
					}
				break;
			    }
								
			case NSLeftMouseDragged: {
				std::clog << "mouseDown: NSLeftMouseDragged occured\n";
				x = (int) mouse.x;
				y = (int) mouse.y;
				[self drawRect:[self frame ]];		
				break;
				}
											
			case NSLeftMouseUp: {
				std::clog << "mouseDown: NSLeftMouseUp occured\n";
				MouseButtonUp = true;
				x = (int) mouse.x;
				y = (int) mouse.y;
				
				/*
				if ([event clickCount] >= 2) //double-click OR right-click
					{//see if the user double clicked on a card to send it up to the FullSuits
					std::clog << "double-click event recieved.\n";
					bool uppd = false;
					//check the top card in the drag_cards
					if ( (CardsBeingDragged.size() == 1) && (hits_card(x,y,CardsBeingDragged.back())) ) {
						//check all the FullSuits to see if something fits
						for (int i = 0; i < NUMBER_OF_FULL_SUITS; i++) {
							if (uppd)
								break;
							//if the top stack is empty and the card in an ace, or...
							if ( ((FullSuits[i].size() == 1) && (CardsBeingDragged.back().number == 0)) 
							     ||  //the card is the same suit and one number higher than the current top card
							     ( (FullSuits[i].back().suit == CardsBeingDragged.back().suit)
								 && (FullSuits[i].back().number == CardsBeingDragged.back().number - 1) ) ) {
								FullSuits[i].push_back(CardsBeingDragged.back());
								CardsBeingDragged.pop_back();
								if (Stacks[StackCardsFrom].size() > 1)
									Stacks[StackCardsFrom].back().faceup = true;
								cont = false;
								uppd = true;
								if (prefs.scoring == 1)
									score += 10;
								else
									score += 5;
								break;
								}
							}
						}					
					}
				*/
				
				
				if (!CardsBeingDragged.size()) {
					// we aren't dragging, so check for mouse click on main card deck
					if ((Deck.size() > 1) && (hits_card(x,y,Deck.back()))) {
						// user clicked the card deck
						for (int Stack = 0; Stack < NUMBER_OF_STACKS; Stack++) {
							if (Stacks[Stack].size() == 1) {
								std::clog << "mouseDown: Can't deal cards when there is an empty stack\n";
								//use a sheet to tell the user they won.
								userMessage.message = "Error";
								userMessage.info = "Sorry, you can't deal cards when there's an empty pile.";
								return;
							    }
						    }
						// deal cards because it's not empty
						for (int Stack = 0; Stack < NUMBER_OF_STACKS; Stack++) {
							Stacks[Stack].push_back(Deck.back());
							Stacks[Stack].back().faceup = true;
							Deck.pop_back();
							}
						[self AddMove:0 :0 :0];   // set _numberOfCardsMoved to 0 to indicate a deal occured
						break;
						}					
					break;
					}
				
				// dragging cards, so see if it hit one of the Stacks
				for (int i = 0; i < NUMBER_OF_STACKS; i++) {
					if (hits_card (x, y, Stacks[i].back(), true)) {
						// hit a stack, so see if it's the same stack indicating user wants program to move cards
						if (i == StackCardsFrom) {
							// case for card on original stack, so user wants program to find good move
							std::clog << "hit test returned true for original card Stacks[" << i << "]\n"
							<< "drag_cards[0] value of: suit " << CardsBeingDragged[0].suit << ", # " 
							<< CardsBeingDragged[0].number << "\n";
							// seed the BestStack with the stack where card(s) originated
							int BestSize = CardsBeingDragged.size();
							int BestStack = StackCardsFrom;
						    std::clog << "starting best size = " << BestSize << ", best stack = " << BestStack << "\n";
							for (int Stack=0; Stack < NUMBER_OF_STACKS; Stack++) {
								if (Stack == StackCardsFrom) 
									continue;   // ignore originating stack, prefer to move cards if possible
								if ((Stacks[Stack].size() == 1) ||
									((Stacks[Stack].back().faceup == true) && 
									 (Stacks[Stack].back().number == CardsBeingDragged[0].number+1))) {
									// found a potential stack, see if it's the best one so far
									// starting size is the size of the drag group
									int ThisSize = CardsBeingDragged.size();
									if (Stacks[Stack].back().suit == CardsBeingDragged[0].suit)
										// if top of stack matches the drag groups suit then add any matching cards to the size
										ThisSize += [self SizeOfSequentialSameSuitCards:(int) Stack];
									if (ThisSize < BestSize) 
										continue;
									if ((ThisSize == BestSize) &&
										(BestStack != StackCardsFrom) &&
										((Stacks[Stack].size() == 1) && (Stacks[BestStack].size() > 1)))
											// prefer not wasting empty stack if there is another stack as good to place card
											continue;
									BestSize = ThisSize;
									BestStack = Stack;
									std::clog << "setting best size = " << BestSize << ", best stack = " << BestStack << "\n";
									}
								}
							if (BestStack == StackCardsFrom)
								// nothing better than where it started from, so put it back
								break;
							for (int z = 0; z < (int) CardsBeingDragged.size(); z++)
								Stacks[BestStack].push_back(CardsBeingDragged[z]);
							[self AddMove:StackCardsFrom :BestStack :CardsBeingDragged.size()];
							if (Stacks[StackCardsFrom].size() > 1)
								Stacks[StackCardsFrom].back().faceup = true;
							CardsBeingDragged.clear();
							std::clog << "program move: cleared the CardsBeingDragged list, BestStack=" << BestStack 
							          << ", BestSize=" << BestSize
							          << "\n";
							}
						else if (Stacks[i].size() == 1) {
							// case for card dropped on empty stack
							std::clog << "hit test returned true for empty card Stacks[" << i << "]\n"
									  << "drag_cards[0] value of: " << CardsBeingDragged[0].suit << "  " 
									  << CardsBeingDragged[0].number << "\n";
							for (int z = 0; z < (int) CardsBeingDragged.size(); z++)
								Stacks[i].push_back(CardsBeingDragged[z]);
							[self AddMove:StackCardsFrom :i :CardsBeingDragged.size()];
							if (Stacks[StackCardsFrom].size() > 1)
								Stacks[StackCardsFrom].back().faceup = true;
							CardsBeingDragged.clear();
							std::clog << "empty stack move: cleared the CardsBeingDragged list\n";
							if ((prefs.scoring == 1) && (StackCardsFrom == 10))
								score += 5;
							}
						else if (CardsBeingDragged[0].number+1 == Stacks[i].back().number) {  
							// case for card stack not empty and dragged card is sequential to stack bottom
							std::clog << "hit test returned true for non-empty card Stacks[" << i << "]\n"
									  << "drag_cards[0] value of: " << CardsBeingDragged[0].suit << "  " 
									  << CardsBeingDragged[0].number << "\n";
							for (int z = 0; z < (int) CardsBeingDragged.size(); z++)
								Stacks[i].push_back(CardsBeingDragged[z]);
							[self AddMove:StackCardsFrom :i :CardsBeingDragged.size()];
							if (Stacks[StackCardsFrom].size() > 1)
								Stacks[StackCardsFrom].back().faceup = true;
							CardsBeingDragged.clear();
							std::clog << "non-empty stack move: cleared the CardsBeingDragged list\n";
							}
						break;
					    }
					}
				
				if (CardsBeingDragged.size()) {
					// still dragging cards, so see if it hit one of the FullSuits
					for (int i = 0; i < NUMBER_OF_FULL_SUITS; i++) {
						if (hits_card(x,y,FullSuits[i].back())) {
							// if the FullSuit stack is empty and the dragged cards are a complete suit drop them
							std::clog << "mouseDown: checking dragged cards for full suit, size = " << CardsBeingDragged.size() << "\n";
							if ((FullSuits[i].size() == 1) && (CardsBeingDragged.size() == NUMBER_OF_CARDS_IN_SUIT)) {
								for (int z = 0; z < (int) CardsBeingDragged.size(); z++)
									FullSuits[i].push_back(CardsBeingDragged[z]);
								[self AddMove:StackCardsFrom :i :CardsBeingDragged.size()*-1];
								if (Stacks[StackCardsFrom].size() > 1)
									Stacks[StackCardsFrom].back().faceup = true;
								CardsBeingDragged.clear();
								std::clog << "full suit move: cleared the CardsBeingDragged list\n";
								break;
								}
							}
						}
				    }
				
				if (CardsBeingDragged.size()) {
					// if we get here cards being dragged could not be dropped, so return them to their origin stack
					for (int i = 0; i < (int) CardsBeingDragged.size(); i++) 
						Stacks[StackCardsFrom].push_back(CardsBeingDragged[i]);
					CardsBeingDragged.clear();
					std::clog << "return to stack move: cleared the CardsBeingDragged list\n";
					
					break;
					}
			    }
				
			default:
				break;
			}
		} while( (!MouseButtonUp) && (event = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask]) );
	
	[self drawRect:[self frame]];
	}
@end
