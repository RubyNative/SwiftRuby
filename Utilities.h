//
//  Utilities.h
//  SwiftRuby
//
//  Created by John Holdsworth on 12/10/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/Utilities.h#9 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//

#ifndef Utilities_h
#define Utilities_h

#import <Foundation/Foundation.h>

extern NSArray<NSString *> * _Nonnull instanceVariablesForClass( Class _Nonnull cls, NSMutableArray<NSString *> * _Nonnull ivarNames );
extern NSArray<NSString *> * _Nonnull methodSymbolsForClass( Class _Nonnull cls, NSMutableArray<NSString *> * _Nonnull syms );

extern NSString * _Nonnull kCatchLevels;

extern void _try( void (^ _Nonnull tryBlock)() );
extern void _catch( void (^ _Nonnull catchBlock)( NSException * _Nonnull e ) );
extern void _throw( NSException * _Nonnull e );

extern int _system( const char * _Nonnull command );
extern FILE * _Nullable _popen( const char * _Nonnull command, const char * _Nonnull perm );
extern int _pclose( FILE * _Nonnull fp );

extern void execArgv( NSString * _Nonnull executable, NSArray<NSString *> * _Nonnull arguments );
extern pid_t spawnArgv( NSString * _Nonnull executable, NSArray<NSString *> * _Nonnull arguments );
extern int fcntl3( int fildes, int cmd, int flags );

#endif /* Utilities_h */
