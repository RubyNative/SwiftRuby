//
//  Utilities.h
//  SwiftRuby
//
//  Created by John Holdsworth on 12/10/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/Utilities.h#6 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//

#ifndef Utilities_h
#define Utilities_h

#import <Foundation/Foundation.h>

extern NSArray<NSString *> * _Nonnull instanceVariablesForClass( Class cls, NSMutableArray<NSString *> * _Nonnull ivarNames );
extern NSArray<NSString *> * _Nonnull methodSymbolsForClass( Class cls );

extern __nonnull NSString *kCatchLevels;

extern void _try( void (^tryBlock)() );
extern void _catch( void (^catchBlock)( NSException * _Nonnull e ) );
extern void _throw( _Nonnull NSException *e );

extern int _system( const char *command );
extern FILE *_popen( const char *command, const char *perm );
extern int _pclose( FILE *fp );

extern void execArgv( NSString * _Nonnull executable, NSArray<NSString *> * _Nonnull arguments );
extern pid_t spawnArgv( NSString * _Nonnull executable, NSArray<NSString *> * _Nonnull arguments );
extern int fcntl3( int fildes, int cmd, int flags );

#endif /* Utilities_h */
