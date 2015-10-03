//
//  Utilities.m
//  RubyNative
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/RubyKit/Utilities.m#2 $
//
//  Repo: https://github.com/RubyNative/RubyKit
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>

// From Jay Freeman's https://www.youtube.com/watch?v=Ii-02vhsdVk

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

NSArray *instanceVariablesForClass( Class cls, NSMutableArray *ivarNames ) {
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

NSArray *methodSymbolsForClass( Class cls ) {
    NSMutableArray<NSString *> *syms = [NSMutableArray new];

    struct _in_objc_class *swiftClass = (__bridge struct _in_objc_class *)cls;

    IMP *sym_start = swiftClass->dispatch,
        *sym_end = (IMP *)((char *)swiftClass + swiftClass->mdsize - 2*sizeof(IMP));

    for ( IMP *sym_ptr = sym_start ; sym_ptr < sym_end ; sym_ptr++ ) {
        Dl_info info;
        if ( dladdr( *sym_ptr, &info ) && info.dli_sname )
            [syms addObject:[NSString stringWithUTF8String:info.dli_sname]];
//        else
//            NSLog( @"%ld!!!!%ld!!!!!!", sym_ptr-sym_start, sym_end-sym_ptr );
    }

    return syms;
}
