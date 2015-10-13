//
//  Utilities.m
//  RubyNative
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/RubyKit/Utilities.m#6 $
//
//  Repo: https://github.com/RubyNative/RubyKit
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>

// Thanks to Jay Freeman's https://www.youtube.com/watch?v=Ii-02vhsdVk

struct _in_objc_class {

    Class meta, supr;
    void *cache, *vtable;
    struct _in_objc_ronly *internal;

    // data new to swift
    int f1, f2; // added for 1.0 Beta5
    int size, tos, mdsize, eight;

    struct __swift_data {
        unsigned long flags;
        const char *className;
        int fieldcount, flags2;
        const char *ivarNames;
        struct _swift_field **(*get_field_data)();
    } *swiftData;

    IMP dispatch[1];
};

NSArray<NSString *> *instanceVariablesForClass( Class cls, NSMutableArray<NSString *> *ivarNames ) {
    Class superCls = class_getSuperclass( cls );
    if ( superCls )
        instanceVariablesForClass( superCls, ivarNames );

    struct _in_objc_class *swiftClass = (__bridge struct _in_objc_class *)cls;

    if ( (uintptr_t)swiftClass->internal & 0x1 ) {
        const char *names = swiftClass->swiftData->ivarNames;

        for ( int f = 0 ; f < swiftClass->swiftData->fieldcount ; f++ ) {
            [ivarNames addObject:[NSString stringWithFormat:@"%@.%@", NSStringFromClass( cls ),
                                  [NSString stringWithUTF8String:names]]];
            names += strlen( names ) + 1;
        }
    }
    else {
        unsigned ic;
        Ivar *ivars = class_copyIvarList( cls, &ic );
        for ( int i=0 ; i<ic ; i++ )
            [ivarNames addObject:[NSString stringWithFormat:@"%@.%@", NSStringFromClass( cls ),
                                  [NSString stringWithUTF8String:ivar_getName( ivars[i] )]]];
    }

    return ivarNames;
}

NSArray<NSString *> *methodSymbolsForClass( Class cls ) {
    NSMutableArray<NSString *> *syms = [NSMutableArray new];

    struct _in_objc_class *swiftClass = (__bridge struct _in_objc_class *)cls;

    IMP *sym_start = swiftClass->dispatch,
        *sym_end = (IMP *)((char *)swiftClass + swiftClass->mdsize - 2*sizeof(IMP));

    Dl_info info;
    for ( IMP *sym_ptr = sym_start ; sym_ptr < sym_end ; sym_ptr++ )
        if ( dladdr( *sym_ptr, &info ) && info.dli_sname )
            [syms addObject:[NSString stringWithUTF8String:info.dli_sname]];

    return syms;
}

static NSString *kLastExceptionKey = @"RubyKitException";
static NSString *kCatchLevels = @"RubyCatchLevels";

void _try( void (^tryBlock)() ) {
    NSMutableDictionary *threadDictionary = [NSThread currentThread].threadDictionary;
    threadDictionary[kCatchLevels] = @([threadDictionary[kCatchLevels] intValue]+1);
    threadDictionary[kLastExceptionKey]  = nil;
    @try {
        tryBlock();
    }
    @catch (NSException *e) {
        threadDictionary[kLastExceptionKey] = e;
    }
    threadDictionary[kCatchLevels] = @([threadDictionary[kCatchLevels] intValue]-1);
}

void _catch( void (^catchBlock)( NSException *e ) ) {
    NSException *e = [NSThread currentThread].threadDictionary[kLastExceptionKey];
    if ( e ) {
        catchBlock( e );
    }
}

void _throw( NSException *e ) {
    if ( [[NSThread currentThread].threadDictionary[kCatchLevels] intValue] > 0 )
        @throw e;
    else {
        NSLog( @"RubyKit: Uncaught Exception: name: %@, reason: %@, userInfo: %@", e.name, e.reason, e.userInfo );
        abort();
    }
}
