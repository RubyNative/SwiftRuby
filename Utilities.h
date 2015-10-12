//
//  Utilities.h
//  RubyKit
//
//  Created by John Holdsworth on 12/10/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//

#ifndef Utilities_h
#define Utilities_h

#import <Foundation/Foundation.h>

extern NSArray<NSString *> *instanceVariablesForClass( Class cls, NSMutableArray<NSString *> *ivarNames );
extern NSArray<NSString *> *methodSymbolsForClass( Class cls );

extern void _try( void (^tryBlock)() );
extern void _catch( void (^catchBlock)( NSException *e ) );
extern void _throw( NSException *e );

#endif /* Utilities_h */
