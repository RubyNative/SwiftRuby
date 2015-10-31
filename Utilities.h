//
//  Utilities.h
//  SwiftRuby
//
//  Created by John Holdsworth on 12/10/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/Utilities.h#3 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//

#ifndef Utilities_h
#define Utilities_h

#import <Foundation/Foundation.h>

extern NSArray<NSString *> *instanceVariablesForClass( Class cls, NSMutableArray<NSString *> *ivarNames );
extern NSArray<NSString *> *methodSymbolsForClass( Class cls );

extern NSString *kCatchLevels;

extern void _try( void (^tryBlock)() );
extern void _catch( void (^catchBlock)( NSException *e ) );
extern void _throw( NSException *e );

extern void execArgv( NSString *executable, NSArray<NSString *> *arguments );
extern pid_t spawnArgv( NSString *executable, NSArray<NSString *> *arguments );

#endif /* Utilities_h */
